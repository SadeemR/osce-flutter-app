import 'dart:ui' show ImageFilter;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/osce_case.dart';
import '../services/api_service.dart';
import '../services/file_processor.dart';
import '../state/rubric_store.dart';
import '../state/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'preparation_screen.dart';
import 'rubric_library_screen.dart';
import 'settings_screen.dart';

class CaseInputScreen extends StatefulWidget {
  const CaseInputScreen({super.key});

  @override
  State<CaseInputScreen> createState() => _CaseInputScreenState();
}

class _CaseInputScreenState extends State<CaseInputScreen> {
  final _case = OsceCase.empty;
  final _patient = TextEditingController();
  final _complaint = TextEditingController();
  final _results = TextEditingController();
  final _situation = TextEditingController();
  final _studentNumber = TextEditingController();
  final _hiddenInfo = TextEditingController();
  StationType _stationType = StationType.badNews;
  final _hiddenFocus = FocusNode();
  bool _showHidden = false;

  String? _caseFileName;
  List<int>? _caseFileData;
  String? _caseFileText;
  String? _caseFileError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the start button as the student types.
    for (final c in [_patient, _complaint, _results, _situation, _hiddenInfo]) {
      c.addListener(_onFieldChanged);
    }
    _hiddenFocus.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _patient,
      _complaint,
      _results,
      _situation,
      _hiddenInfo,
      _studentNumber
    ]) {
      c.dispose();
    }
    _hiddenFocus.dispose();
    super.dispose();
  }

  ApiService _api() => ApiService(context.read<AppSettings>().apiBaseURL);

  bool get _isFormValid {
    final manual = _patient.text.trim().isNotEmpty ||
        _complaint.text.trim().isNotEmpty ||
        _results.text.trim().isNotEmpty ||
        _situation.text.trim().isNotEmpty ||
        _hiddenInfo.text.trim().isNotEmpty;
    final hasFile = (_caseFileText?.trim().isNotEmpty ?? false);
    return manual || hasFile;
  }

  Future<void> _pickCaseFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupportedFileType.allowedExtensions,
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;
    final f = res.files.single;
    setState(() => _caseFileError = null);
    try {
      final processed = FileProcessor.process(
        fileName: f.name,
        bytes: f.bytes!,
        extension: f.extension ?? '',
      );
      setState(() {
        _caseFileName = processed.fileName;
        _caseFileData = processed.rawData;
        _caseFileText =
            processed.needsServerParsing ? null : processed.extractedText;
        _case.attachedFileName = processed.fileName;
        _case.attachedFileText = processed.extractedText;
      });
    } catch (e) {
      setState(() => _caseFileError = e.toString());
    }
  }

  void _removeCaseFile() {
    setState(() {
      _caseFileName = null;
      _caseFileData = null;
      _caseFileText = null;
      _case.attachedFileName = null;
      _case.attachedFileText = null;
    });
  }

  void _loadSample() {
    final s = OsceCase.sample;
    setState(() {
      _patient.text = s.patientInfo;
      _complaint.text = s.complaint;
      _results.text = s.results;
      _situation.text = s.situation;
      _hiddenInfo.text = s.hiddenInfo;
      _stationType = s.stationType;
    });
  }

  Future<void> _submit() async {
    final settings = context.read<AppSettings>();
    final session = context.read<SessionManager>();
    final store = context.read<RubricStore>();

    if (!_isFormValid) {
      _showError('الرجاء تعبئة حقل واحد على الأقل أو إرفاق ملف.');
      return;
    }

    _case
      ..patientInfo = _patient.text
      ..complaint = _complaint.text
      ..results = _results.text
      ..situation = _situation.text
      ..hiddenInfo = _hiddenInfo.text
      ..stationType = _stationType
      ..language = settings.language.code;

    setState(() => _submitting = true);
    final api = _api();

    try {
      session.activeRubricTemplate = store.activeTemplate;

      final number = int.tryParse(_studentNumber.text);
      if (number != null) session.studentNumber = number;

      final prompt = await api.generatePrompt(_case);
      if (prompt != null) _case.aiGeneratedPrompt = prompt;

      final startResult = await api.updateCase(
        _case,
        fileBytes: _caseFileData,
        fileName: _caseFileName,
      );

      session.currentCase = _case;
      session.sessionId = startResult.sessionId;
      session.caseFileData = _caseFileData;
      session.caseFileName = _caseFileName;

      session.messages = [
        ChatMessage(
          sender: MessageSender.parent,
          text: startResult.initialMessage,
        )
      ];

      session.sessionStartTime = DateTime.now();
      session.touch();

      if (!mounted) return;

      // Replace the whole stack so the student can't go back to the form
      // (which still holds the hidden patient details).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PreparationScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    final s = AppStrings(context.read<AppSettings>().isArabic);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.errorTitle),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.ok))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _stationCard(),
      _caseFileCard(),
      _manualForm(),
      _hiddenInfoCard(),
      _rubricSelector(),
      _studentInfo(),
      _submitButton(),
    ];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _heroHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                for (var i = 0; i < sections.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FadeSlideIn(
                      delay: AppMotion.stagger * (i + 2),
                      child: sections[i],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    final settings = context.watch<AppSettings>();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x40FF7A59)),
                  ),
                  child: const Icon(Icons.medical_services_outlined,
                      color: AppColors.accent, size: 20),
                ),
                const Spacer(),
                _headerIcon(Icons.assignment_outlined, 'أوراق التقييم',
                    () => _open(const RubricLibraryScreen())),
                const SizedBox(width: 8),
                _headerIcon(Icons.tune_rounded, 'الإعدادات',
                    () => _open(const SettingsScreen())),
              ],
            ),
            const SizedBox(height: 28),
            const FadeSlideIn(
              child: Text('OSCE Simulation',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 30,
                      height: 1.15,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            const FadeSlideIn(
              delay: AppMotion.stagger,
              child: Text('Doctor–Patient Communication Platform',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: AppMotion.stagger * 2,
              child: _languageSwitch(settings),
            ),
          ],
        ),
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _headerIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return Pressable(
      scale: 0.9,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  /// Segmented control with a sliding coral thumb.
  Widget _languageSwitch(AppSettings settings) {
    const langs = AppLanguage.values;
    final index = langs.indexOf(settings.language);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / langs.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final visualIndex = rtl ? langs.length - 1 - index : index;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: AppMotion.base,
              curve: AppMotion.enter,
              left: w * visualIndex,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            Row(
              children: langs.map((lang) {
                final selected = settings.language == lang;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      settings.setLanguage(lang);
                      _case.language = lang.code;
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: AppMotion.base,
                        style: TextStyle(
                          fontFamily:
                              DefaultTextStyle.of(context).style.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected
                              ? AppColors.onAccent
                              : AppColors.textSecondary,
                        ),
                        child: Text(lang.displayName),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }),
    );
  }

  // ===== نوع المحطة =====
  Widget _stationCard() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    final options = [
      (StationType.badNews, Icons.favorite_border_rounded, s.stationBadNews,
          s.stationBadNewsHint),
      (StationType.historyTaking, Icons.assignment_ind_outlined,
          s.stationHistory, s.stationHistoryHint),
    ];
    final hint = options.firstWhere((o) => o.$1 == _stationType).$4;
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(icon: Icons.medical_information_outlined, text: s.stationType),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _StationOption(
                    icon: options[i].$2,
                    label: options[i].$3,
                    selected: _stationType == options[i].$1,
                    onTap: () => setState(() => _stationType = options[i].$1),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: AppMotion.base,
            transitionBuilder: (child, a) =>
                FadeTransition(opacity: a, child: child),
            child: Text(hint,
                key: ValueKey(hint),
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  bool get _blurHidden =>
      !_showHidden &&
      !_hiddenFocus.hasFocus &&
      _hiddenInfo.text.trim().isNotEmpty;

  // ===== المعلومات السرية =====
  Widget _hiddenInfoCard() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            icon: Icons.lock_outline_rounded,
            text: s.hiddenInfo,
            trailing: IconButton(
              tooltip: _showHidden ? 'Hide' : 'Show',
              onPressed: () => setState(() => _showHidden = !_showHidden),
              icon: AnimatedSwitcher(
                duration: AppMotion.base,
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: Icon(
                  _showHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  key: ValueKey(_showHidden),
                  size: 20,
                  color: _showHidden ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Blurred unless the eye is on or the field is being typed in,
          // so someone glancing at the screen can't read the secret details.
          TweenAnimationBuilder<double>(
            tween: Tween(end: _blurHidden ? 7.0 : 0.0),
            duration: AppMotion.base,
            builder: (context, sigma, child) => sigma < 0.05
                ? child!
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: child,
                  ),
            child: TextField(
              controller: _hiddenInfo,
              focusNode: _hiddenFocus,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(hintText: s.hiddenInfoHint),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.visibility_off_outlined,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(s.hiddenInfoNote,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== بطاقة ملف الحالة =====
  Widget _caseFileCard() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(icon: Icons.note_add_outlined, text: s.caseFile),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.enter,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SizeTransition(sizeFactor: a, child: child),
            ),
            child: _caseFileName != null
                ? Container(
                    key: const ValueKey('file'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: const Color(0x40FF7A59)),
                    ),
                    child: Row(
                      children: [
                        Icon(fileIconFor(_caseFileName!),
                            color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_caseFileName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text)),
                              Text(
                                  _caseFileText == null
                                      ? s.serverParsed
                                      : s.locallyExtracted,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _removeCaseFile,
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ActionTile(
                    key: const ValueKey('empty'),
                    icon: Icons.upload_file_outlined,
                    title: s.attachFile,
                    subtitle: 'PDF · TXT · CSV · JSON',
                    onTap: _pickCaseFile,
                  ),
          ),
          if (_caseFileError != null) ...[
            const SizedBox(height: 8),
            Text(_caseFileError!,
                style: const TextStyle(fontSize: 12, color: AppColors.danger)),
          ],
          const SizedBox(height: 10),
          Text(s.orFillManually,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _manualForm() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return CardContainer(
      child: Column(
        children: [
          SectionLabel(
            icon: Icons.edit_note_rounded,
            text: s.manualInput,
            trailing: Text(s.optionalWithFile,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 18),
          CaseFormField(
              label: s.patient,
              placeholder: s.patientHint,
              controller: _patient),
          const SizedBox(height: 14),
          CaseFormField(
              label: s.complaint,
              placeholder: s.complaintHint,
              controller: _complaint,
              isMultiline: true),
          const SizedBox(height: 14),
          CaseFormField(
              label: s.results,
              placeholder: s.resultsHint,
              controller: _results,
              isMultiline: true),
          const SizedBox(height: 14),
          CaseFormField(
              label: s.situation,
              placeholder: s.situationHint,
              controller: _situation,
              isMultiline: true),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _loadSample,
              icon: const Icon(Icons.auto_awesome_outlined, size: 16),
              label: Text(s.loadSample, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // ===== اختيار ورقة التقييم =====
  Widget _rubricSelector() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    final store = context.watch<RubricStore>();
    final active = store.activeTemplate;
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
              icon: Icons.assignment_turned_in_outlined, text: s.rubricSheet),
          const SizedBox(height: 14),
          if (active != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0x403DD68C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(active.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text)),
                        Text(
                            '${active.criteria.length} · ${active.sourceFileName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _open(const RubricLibraryScreen()),
                    child: Text(s.changeRubric),
                  ),
                ],
              ),
            )
          else
            ActionTile(
              icon: Icons.add_circle_outline_rounded,
              title: s.addRubric,
              onTap: () => _open(const RubricLibraryScreen()),
            ),
          if (active == null) ...[
            const SizedBox(height: 10),
            Text(s.noRubricNote,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  // ===== معلومات الطالب =====
  Widget _studentInfo() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(icon: Icons.badge_outlined, text: s.studentInfo),
          const SizedBox(height: 16),
          CaseFormField(
              label: s.studentNumber,
              placeholder: s.studentNumberHint,
              controller: _studentNumber,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: () {
                if (_isFormValid && !_submitting) _submit();
              }),
        ],
      ),
    );
  }

  // ===== زر البدء =====
  Widget _submitButton() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return PrimaryButton(
      label: s.startExam,
      icon: Icons.play_arrow_rounded,
      loading: _submitting,
      loadingLabel: s.initializing,
      onPressed: _isFormValid ? _submit : null,
    );
  }
}

class _StationOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StationOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    return Pressable(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: AppMotion.base,
                curve: AppMotion.enter,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: AppMotion.base,
                style: TextStyle(
                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                child: Text(label, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

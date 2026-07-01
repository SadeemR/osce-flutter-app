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

  String? _caseFileName;
  List<int>? _caseFileData;
  String? _caseFileText;
  String? _caseFileError;
  bool _submitting = false;

  ApiService _api() => ApiService(context.read<AppSettings>().apiBaseURL);

  bool get _isFormValid {
    final manual = _patient.text.trim().isNotEmpty ||
        _complaint.text.trim().isNotEmpty ||
        _results.text.trim().isNotEmpty ||
        _situation.text.trim().isNotEmpty;
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

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PreparationScreen()),
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
    return Scaffold(
      backgroundColor: AppColors.offWhiteCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _heroHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _caseFileCard(),
                  const SizedBox(height: 20),
                  _manualForm(),
                  const SizedBox(height: 20),
                  _rubricSelector(),
                  const SizedBox(height: 20),
                  _studentInfo(),
                  const SizedBox(height: 20),
                  _submitButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    final settings = context.watch<AppSettings>();
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RubricLibraryScreen())),
                    icon: const Icon(Icons.assignment_outlined,
                        color: Colors.white),
                    tooltip: 'أوراق التقييم',
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    tooltip: 'الإعدادات',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              const Text('OSCE Simulation',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Doctor–Patient Communication Platform',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: AppLanguage.values.map((lang) {
                  final selected = settings.language == lang;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () {
                        settings.setLanguage(lang);
                        _case.language = lang.code;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: selected ? 0 : 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Text(lang.flag),
                            const SizedBox(width: 6),
                            Text(lang.displayName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: selected
                                        ? AppColors.purple
                                        : Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
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
          _CardLabel(icon: Icons.note_add_outlined, text: s.caseFile),
          const SizedBox(height: 12),
          if (_caseFileName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(fileIconFor(_caseFileName!), color: AppColors.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_caseFileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                            _caseFileText == null
                                ? s.serverParsed
                                : s.locallyExtracted,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeCaseFile,
                    icon: Icon(Icons.cancel,
                        color: Colors.red.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: _pickCaseFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.upload_file, color: AppColors.purple),
                    const SizedBox(width: 8),
                    Text(s.attachFile,
                        style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Text('PDF · TXT · CSV · JSON',
                        style: TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ),
            ),
          if (_caseFileError != null) ...[
            const SizedBox(height: 8),
            Text(_caseFileError!,
                style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
          const SizedBox(height: 8),
          Text(s.orFillManually,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _manualForm() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return CardContainer(
      child: Column(
        children: [
          Row(
            children: [
              Text(s.manualInput,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Text(s.optionalWithFile,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 14),
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
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _loadSample,
              child: Text(s.loadSample,
                  style:
                      const TextStyle(color: AppColors.purple, fontSize: 13)),
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
          _CardLabel(
              icon: Icons.assignment_turned_in_outlined, text: s.rubricSheet),
          const SizedBox(height: 12),
          if (active != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.ratingGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.ratingGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(active.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            '${active.criteria.length} · ${active.sourceFileName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RubricLibraryScreen())),
                    child: Text(s.changeRubric,
                        style: const TextStyle(color: AppColors.purple)),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RubricLibraryScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.8),
                      width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: AppColors.purple),
                    const SizedBox(width: 8),
                    Text(s.addRubric,
                        style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
              ),
            ),
          if (active == null) ...[
            const SizedBox(height: 8),
            Text(s.noRubricNote,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ],
      ),
    );
  }

  // ===== معلوومات الطالب =====
  Widget _studentInfo() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(icon: Icons.badge_outlined, text: s.studentInfo),
          const SizedBox(height: 14),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isFormValid && !_submitting) ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          disabledBackgroundColor: Colors.grey,
          foregroundColor: AppColors.purple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Builder(builder: (context) {
          final s = AppStrings(context.watch<AppSettings>().isArabic);
          return _submitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.purple)),
                    const SizedBox(width: 12),
                    Text(s.initializing,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(s.startExam,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                );
        }),
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CardLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.purple),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.purple)),
      ],
    );
  }
}

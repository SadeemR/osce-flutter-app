import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/evaluation_result.dart';
import '../services/api_service.dart';
import '../state/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'case_input_screen.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final session = context.read<SessionManager>();
    if (session.evaluationResult != null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ApiService(context.read<AppSettings>().apiBaseURL);
    try {
      final result = await api.evaluate(
          sessionId: session.sessionId,
          rubricText: session.activeRubricText,
          messages: session.messages);
      session.evaluationResult = result;
      session.touch();
      await api.saveResult(
          sessionId: session.sessionId,
          studentNumber: session.studentNumber,
          result: result);
      // حفظ درجة الطالب تلقائياً من نتيجة التقييم
      if (session.studentNumber > 0) {
        await api.sendStudent(
            number: session.studentNumber,
            grade: result.totalPercentage);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _ratingColor(String rating) => AppColors.forRating(rating);

  String _duration(SessionManager s) {
    if (s.sessionStartTime == null) return 'N/A';
    final e = DateTime.now().difference(s.sessionStartTime!).inSeconds;
    return '${e ~/ 60}:${(e % 60).toString().padLeft(2, '0')}';
  }

  void _share(EvaluationResult r) {
    final b = StringBuffer('OSCE Evaluation Results\n');
    b.writeln('Rubric: ${r.rubricUsed}');
    b.writeln(
        'Overall: ${r.totalPercentage.toStringAsFixed(0)}% — ${r.overallRating}\n');
    for (final s in r.scores) {
      b.writeln(
          '• ${s.criterionName}: ${s.score.toStringAsFixed(1)}/${s.maxScore.toStringAsFixed(0)}');
    }
    if (r.overallFeedback != null) b.writeln('\nFeedback:\n${r.overallFeedback}');
    Share.share(b.toString());
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final result = session.evaluationResult;

    // The exam can't be left with the back button.
    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
            AppStrings(context.watch<AppSettings>().isArabic).evaluationResults),
        actions: [
          if (result != null)
            IconButton(
                onPressed: () => _share(result),
                icon: const Icon(Icons.ios_share_rounded)),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.slow,
          switchInCurve: AppMotion.enter,
          child: _loading
              ? _loadingView()
              : _error != null
                  ? _errorView()
                  : result != null
                      ? _results(session, result)
                      : _loadingView(),
        ),
      ),
    ),
    );
  }

  Widget _loadingView() {
    final s = AppStrings(context.read<AppSettings>().isArabic);
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pulse(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x40FF7A59)),
              ),
              child: const Icon(Icons.insights_rounded,
                  color: AppColors.accent, size: 34),
            ),
          ),
          const SizedBox(height: 22),
          Text(s.analyzingPerformance,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(s.aiAnalyzing,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5)),
          ),
          const SizedBox(height: 22),
          const SizedBox(
            width: 140,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ],
      ),
    );
  }

  Widget _errorView() => Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 32, color: AppColors.warning),
              ),
              const SizedBox(height: 16),
              Text(
                  AppStrings(context.read<AppSettings>().isArabic)
                      .failedToLoad,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              Text(_error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Pressable(
                child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<SessionManager>().evaluationResult = null;
                      _fetch();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                        AppStrings(context.read<AppSettings>().isArabic)
                            .retry)),
              ),
            ],
          ),
        ),
      );

  Widget _results(SessionManager session, EvaluationResult r) {
    final blocks = <Widget>[
      _overallCard(r),
      _statsRow(session, r),
      _criteriaSection(r),
      if (r.overallFeedback != null && r.overallFeedback!.isNotEmpty)
        _feedbackCard(r.overallFeedback!),
      _summaryCard(session),
      _actions(session, r),
    ];
    return ListView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FadeSlideIn(
              delay: AppMotion.stagger * (i * 2),
              child: blocks[i],
            ),
          ),
      ],
    );
  }

  Widget _overallCard(EvaluationResult r) {
    final color = _ratingColor(r.overallRating);
    final target = (r.totalPercentage / 100).clamp(0.0, 1.0).toDouble();
    return CardContainer(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          SizedBox(
            width: 168,
            height: 168,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: AppMotion.emphasis,
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 12,
                      backgroundColor: AppColors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(v * 100).round()}%',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.text)),
                      const Text('Overall',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: const Duration(milliseconds: 700),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text(r.overallRating,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: color)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Rubric: ${r.rubricUsed}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _statsRow(SessionManager s, EvaluationResult r) {
    Widget tile(IconData i, String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(i, color: AppColors.accent, size: 20),
                const SizedBox(height: 8),
                Text(value,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        tile(Icons.assignment_outlined, 'Criteria', '${r.scores.length}'),
        const SizedBox(width: 8),
        tile(Icons.timer_outlined, 'Duration', _duration(s)),
        const SizedBox(width: 8),
        tile(Icons.chat_bubble_outline_rounded, 'Messages',
            '${s.doctorMessages.length}'),
      ],
    );
  }

  Widget _criteriaSection(EvaluationResult r) {
    final sorted = [...r.scores]..sort((a, b) => b.score.compareTo(a.score));
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
              icon: Icons.bar_chart_rounded,
              text: AppStrings(context.read<AppSettings>().isArabic)
                  .evaluationCriteria),
          const SizedBox(height: 14),
          for (var i = 0; i < sorted.length; i++)
            FadeSlideIn(
              delay: const Duration(milliseconds: 300) + AppMotion.stagger * i,
              child: CriterionRow(
                item: sorted[i],
                barDelay:
                    const Duration(milliseconds: 450) + AppMotion.stagger * i,
              ),
            ),
        ],
      ),
    );
  }

  Widget _feedbackCard(String feedback) {
    return CardContainer(
      borderColor: const Color(0x40FF7A59),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
              icon: Icons.auto_awesome_outlined,
              text: AppStrings(context.read<AppSettings>().isArabic).aiFeedback),
          const SizedBox(height: 12),
          Text(feedback,
              style: const TextStyle(
                  color: AppColors.text, height: 1.65, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _summaryCard(SessionManager s) {
    final c = s.currentCase;
    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 90,
                  child: Text(l,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted))),
              Expanded(
                  child: Text(v,
                      style: const TextStyle(
                          color: AppColors.text, height: 1.45))),
            ],
          ),
        );
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
              icon: Icons.description_outlined,
              text: AppStrings(context.read<AppSettings>().isArabic)
                  .sessionSummary),
          const SizedBox(height: 16),
          if (c.patientInfo.trim().isNotEmpty) row('Patient', c.patientInfo),
          if (c.complaint.trim().isNotEmpty) row('Complaint', c.complaint),
          if (c.results.trim().isNotEmpty) row('Results', c.results),
          if (s.activeRubricTemplate != null)
            row('Rubric', s.activeRubricTemplate!.name),
          row('Messages', '${s.doctorMessages.length}'),
          row('Duration', _duration(s)),
        ],
      ),
    );
  }

  Widget _actions(SessionManager session, EvaluationResult r) {
    final s = AppStrings(context.read<AppSettings>().isArabic);
    return Column(
      children: [
        PrimaryButton(
          label: s.startNewSession,
          icon: Icons.add_rounded,
          onPressed: () {
            session.reset();
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CaseInputScreen()),
                (route) => false);
          },
        ),
        const SizedBox(height: 12),
        Pressable(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => _share(r),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: Text(s.shareResults),
            ),
          ),
        ),
      ],
    );
  }
}

class CriterionRow extends StatefulWidget {
  final EvaluationScore item;
  final Duration barDelay;
  const CriterionRow(
      {super.key, required this.item, this.barDelay = Duration.zero});

  @override
  State<CriterionRow> createState() => _CriterionRowState();
}

class _CriterionRowState extends State<CriterionRow> {
  bool _expanded = false;

  Color get _color => AppColors.forColorName(widget.item.ratingColorName);

  bool get _hasFeedback =>
      widget.item.feedback != null && widget.item.feedback!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final s = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: _expanded ? AppColors.borderStrong : AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: _hasFeedback
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(s.criterionName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text)),
                          ),
                          if (s.weight != 1.0) ...[
                            const SizedBox(width: 6),
                            Tag(text: '×${s.weight.toStringAsFixed(0)}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: s.score.toStringAsFixed(1),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _color)),
                        TextSpan(
                            text: ' / ${s.maxScore.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ]),
                      textDirection: TextDirection.ltr,
                    ),
                    if (_hasFeedback) ...[
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: AppMotion.base,
                        curve: AppMotion.enter,
                        child: const Icon(Icons.expand_more_rounded,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedBar(
                  value: s.percentage / 100,
                  color: _color,
                  delay: widget.barDelay,
                ),
                AnimatedSize(
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                  alignment: Alignment.topCenter,
                  child: _expanded && _hasFeedback
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(s.feedback!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.55,
                                  color: AppColors.textSecondary)),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

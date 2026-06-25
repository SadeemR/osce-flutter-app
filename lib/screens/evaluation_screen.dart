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

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Excellent':
        return AppColors.ratingGreen;
      case 'Good':
        return AppColors.brandPrimary;
      case 'Average':
        return AppColors.apricot;
      default:
        return AppColors.ratingRed;
    }
  }

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

    return Scaffold(
      backgroundColor: AppColors.burgundyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.burgundyBackground,
        automaticallyImplyLeading: false,
        title: Text(AppStrings(context.watch<AppSettings>().isArabic).evaluationResults),
        actions: [
          if (result != null)
            IconButton(
                onPressed: () => _share(result),
                icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _loadingView()
            : _error != null
                ? _errorView()
                : result != null
                    ? _results(session, result)
                    : _loadingView(),
      ),
    );
  }

  Widget _loadingView() {
    final s = AppStrings(context.read<AppSettings>().isArabic);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(s.analyzingPerformance,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(s.aiAnalyzing,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 48, color: AppColors.apricot),
              const SizedBox(height: 12),
              Text(AppStrings(context.read<AppSettings>().isArabic).failedToLoad,
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () {
                    context.read<SessionManager>().evaluationResult = null;
                    _fetch();
                  },
                  child: Text(AppStrings(context.read<AppSettings>().isArabic).retry)),
            ],
          ),
        ),
      );

  Widget _results(SessionManager session, EvaluationResult r) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _overallCard(r),
        const SizedBox(height: 20),
        _statsRow(session, r),
        const SizedBox(height: 20),
        _criteriaSection(r),
        if (r.overallFeedback != null && r.overallFeedback!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _feedbackCard(r.overallFeedback!),
        ],
        const SizedBox(height: 20),
        _summaryCard(session),
        const SizedBox(height: 20),
        _actions(session, r),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _overallCard(EvaluationResult r) {
    final color = _ratingColor(r.overallRating);
    return CardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(r.overallRating,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: r.totalPercentage / 100,
                    strokeWidth: 14,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${r.totalPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                    const Text('Overall',
                        style:
                            TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(100)),
            child: Text('Rubric: ${r.rubricUsed}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(SessionManager s, EvaluationResult r) {
    Widget chip(IconData i, String label, String value, Color color) =>
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Icon(i, color: color),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        );

    return CardContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          chip(Icons.assignment_outlined, 'Criteria', '${r.scores.length}',
              AppColors.brandPrimary),
          chip(Icons.timer_outlined, 'Duration', _duration(s), AppColors.apricot),
          chip(Icons.chat_bubble_outline, 'Messages',
              '${s.doctorMessages.length}', AppColors.burgundyMid),
        ],
      ),
    );
  }

  Widget _criteriaSection(EvaluationResult r) {
    final sorted = [...r.scores]..sort((a, b) => b.score.compareTo(a.score));
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.burgundy),
              const SizedBox(width: 8),
              Text(AppStrings(context.read<AppSettings>().isArabic).evaluationCriteria,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted.map((s) => CriterionRow(item: s)),
        ],
      ),
    );
  }

  Widget _feedbackCard(String feedback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.apricotPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.apricot.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text(AppStrings(context.read<AppSettings>().isArabic).aiFeedback,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.brandPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(feedback,
              style: const TextStyle(color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }

  Widget _summaryCard(SessionManager s) {
    final c = s.currentCase;
    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 90,
                  child: Text('$l:',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600))),
              Expanded(
                  child: Text(v,
                      style: const TextStyle(color: Colors.black54))),
            ],
          ),
        );
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.burgundy),
              const SizedBox(width: 8),
              Text(AppStrings(context.read<AppSettings>().isArabic).sessionSummary,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 20),
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              session.reset();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const CaseInputScreen()),
                  (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(AppStrings(context.read<AppSettings>().isArabic).startNewSession,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _share(r),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.share_outlined),
            label: Text(AppStrings(context.read<AppSettings>().isArabic).shareResults,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class CriterionRow extends StatefulWidget {
  final EvaluationScore item;
  const CriterionRow({super.key, required this.item});

  @override
  State<CriterionRow> createState() => _CriterionRowState();
}

class _CriterionRowState extends State<CriterionRow> {
  bool _expanded = false;

  Color get _color {
    switch (widget.item.ratingColorName) {
      case 'green':
        return AppColors.ratingGreen;
      case 'blue':
        return AppColors.brandPrimary;
      case 'orange':
        return AppColors.apricot;
      default:
        return AppColors.ratingRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: _color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(s.criterionName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (s.weight != 1.0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.apricotLight,
                                  borderRadius: BorderRadius.circular(100)),
                              child: Text('×${s.weight.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.apricot)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s.percentage / 100,
                          minHeight: 6,
                          backgroundColor: Colors.black12,
                          valueColor: AlwaysStoppedAnimation(_color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.score.toStringAsFixed(1),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _color)),
                    Text('/ ${s.maxScore.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54)),
                  ],
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black45),
              ],
            ),
          ),
          if (_expanded && s.feedback != null && s.feedback!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 22, left: 22),
              child: Text(s.feedback!,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
        ],
      ),
    );
  }
}

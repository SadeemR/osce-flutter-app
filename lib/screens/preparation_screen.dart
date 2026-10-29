import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/osce_case.dart';
import '../models/app_settings.dart';
import '../state/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'simulation_screen.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key});

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  int _timeRemaining = 60;
  int _totalTime = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timeRemaining = context.read<AppSettings>().preparationTime;
      _totalTime = _timeRemaining;
      _startTimer();
      setState(() {});
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _timer?.cancel();
        _goToSimulation();
      }
    });
  }

  void _skipToSimulation() {
    _timer?.cancel();
    _goToSimulation();
  }

  void _goToSimulation() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SimulationScreen()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = _timeRemaining ~/ 60;
    final s = (_timeRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // The exam can't be left with the back button.
    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: Text(
            AppStrings(context.watch<AppSettings>().isArabic).preparationPhase),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            children: [
              FadeSlideIn(child: _timerCard()),
              const SizedBox(height: 16),
              FadeSlideIn(delay: AppMotion.stagger * 2, child: _caseCard()),
            ],
          ),
        ),
      ),
    ),
    );
  }

  // ===== بطاقة معلومات الحالة =====
  Widget _caseCard() {
    final c = context.watch<SessionManager>().currentCase;
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    final isHistory = c.stationType == StationType.historyTaking;
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            icon: Icons.description_outlined,
            text: s.caseInformation,
            trailing: Tag(
                text: isHistory ? s.stationHistory : s.stationBadNews),
          ),
          const SizedBox(height: 16),
          if (c.patientInfo.trim().isNotEmpty)
            _InfoRow(label: s.patientLabel, value: c.patientInfo),
          if (c.complaint.trim().isNotEmpty)
            _InfoRow(label: s.complaintLabel, value: c.complaint),
          if (c.results.trim().isNotEmpty)
            _InfoRow(label: s.resultsLabel, value: c.results),
          if (c.situation.trim().isNotEmpty)
            _InfoRow(label: s.situationLabel, value: c.situation),
          if (c.attachedFileName != null)
            _InfoRow(label: s.fileLabel, value: c.attachedFileName!),
          const Divider(height: 28),
          SectionLabel(icon: Icons.checklist_rounded, text: s.requiredTasks),
          const SizedBox(height: 12),
          _task(1, isHistory ? s.task1History : s.task1),
          _task(2, isHistory ? s.task2History : s.task2),
          const SizedBox(height: 6),
          Text(s.prepNote,
              style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _task(int n, String text) {
    // Strip a leading "1." / "1-" the strings may already contain.
    final clean = text.replaceFirst(RegExp(r'^\s*[0-9٠-٩]+\s*[.\-)]\s*'), '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('$n',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(clean,
                style: const TextStyle(height: 1.55, color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  Widget _timerCard() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    final fraction = _totalTime == 0 ? 0.0 : _timeRemaining / _totalTime;
    final urgent = _timeRemaining <= 10;
    return CardContainer(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      borderColor: urgent ? const Color(0x55F5B84B) : null,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(s.preparationTime,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          CountdownRing(
            fraction: fraction,
            label: _formattedTime,
            caption: s.preparationPhaseLabel,
            color: urgent ? AppColors.warning : AppColors.accent,
          ),
          const SizedBox(height: 22),
          Pressable(
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _skipToSimulation,
                icon: const Icon(Icons.skip_next_rounded, size: 20),
                label: Text(s.skip),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular countdown that drains smoothly between the one-second ticks.
class CountdownRing extends StatelessWidget {
  final double fraction;
  final String label;
  final String caption;
  final Color color;
  final double size;

  const CountdownRing({
    super.key,
    required this.fraction,
    required this.label,
    required this.caption,
    required this.color,
    this.size = 176,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: AppMotion.slow,
        builder: (context, c, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: fraction.clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.linear,
          builder: (context, v, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.surfaceRaised,
                  valueColor: AlwaysStoppedAnimation(c ?? color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(caption,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(height: 1.5, color: AppColors.text)),
        ],
      ),
    );
  }
}

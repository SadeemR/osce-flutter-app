import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../state/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'simulation_screen.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key});

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  int _timeRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timeRemaining = context.read<AppSettings>().preparationTime;
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
    return Scaffold(
      backgroundColor: AppColors.offWhiteCream,
      appBar: AppBar(
        title: Text(AppStrings(context.watch<AppSettings>().isArabic).preparationPhase),
        backgroundColor: AppColors.offWhiteCream,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _caseCard(),
              const SizedBox(height: 20),
              _timerCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ===== بطاقة معلومات الحالة =====
  Widget _caseCard() {
    final c = context.watch<SessionManager>().currentCase;
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppColors.apricot),
              const SizedBox(width: 8),
              Text(s.caseInformation,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.apricot)),
            ],
          ),
          const Divider(height: 20),
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
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.format_list_numbered,
                  size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.requiredTasks,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.task1, style: const TextStyle(height: 1.6)),
          Text(s.task2, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 4),
          Text(s.prepNote,
              style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _timerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(AppStrings(context.watch<AppSettings>().isArabic).preparationTime,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            _formattedTime,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(AppStrings(context.watch<AppSettings>().isArabic).preparationPhaseLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _skipToSimulation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100)),
                  child: Text(AppStrings(context.watch<AppSettings>().isArabic).skip,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

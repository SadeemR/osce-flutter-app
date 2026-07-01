import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _formattedSim(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '$m min' : '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      backgroundColor: AppColors.purpleDeep,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('مؤقّتات الجلسة'),
          _card(Column(
            children: [
              _sliderRow(
                label: 'وقت التحضير',
                value: settings.preparationTime.toDouble(),
                min: 30,
                max: 180,
                divisions: (180 - 30) ~/ 15,
                display: '${settings.preparationTime} ثانية',
                color: AppColors.purple,
                onChanged: (v) => settings.setPreparationTime(v.round()),
              ),
              const SizedBox(height: 12),
              _sliderRow(
                label: 'وقت المحاكاة',
                value: settings.simulationTime.toDouble(),
                min: 120,
                max: 600,
                divisions: (600 - 120) ~/ 60,
                display: _formattedSim(settings.simulationTime),
                color: AppColors.purple,
                onChanged: (v) => settings.setSimulationTime(v.round()),
              ),
            ],
          )),
          const SizedBox(height: 20),

          _sectionTitle('اللغة الافتراضية'),
          _card(Row(
            children: AppLanguage.values.map((lang) {
              final selected = settings.language == lang;
              return Expanded(
                child: GestureDetector(
                  onTap: () => settings.setLanguage(lang),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.cyan
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? AppColors.cyan
                              : AppColors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text('${lang.flag} ${lang.displayName}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? AppColors.purple : Colors.black54)),
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
          const SizedBox(height: 20),

          _sectionTitle('حول التطبيق'),
          _card(Column(
            children: [
              _aboutRow('التطبيق', 'OSCE Simulator'),
              _aboutRow('الإصدار', '1.0.0'),
              _aboutRow('الجامعة', 'جامعة أم القرى'),
              _aboutRow('القسم', 'علوم الحاسب'),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('سياسة الخصوصية'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.purple)),
      );

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.cardCream,
            borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(display, style: const TextStyle(color: Colors.black54)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _aboutRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(l, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(v, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget section(String title, String body) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(body,
                  style: const TextStyle(color: Colors.black54, height: 1.6)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.purpleDeep,
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('سياسة الخصوصية',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('آخر تحديث: مايو 2026',
              style: TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 16),
          section('البيانات التي نجمعها',
              'نجمع رقم الطالب، الدرجات، ونصوص المحادثات أثناء محاكاة OSCE.'),
          section('كيف نستخدم بياناتك',
              'تُستخدم البيانات حصريًا لتقييم أداء الطلاب في اختبارات OSCE. لا نبيع أو نشارك بياناتك مع أطراف ثالثة.'),
          section('تخزين البيانات',
              'تُخزَّن البيانات بأمان على خوادمنا. تُعالَج بيانات المحادثة بواسطة Claude AI من Anthropic لأغراض التقييم.'),
          section('تواصل معنا',
              'لأي استفسار يخص الخصوصية، يُرجى التواصل مع قسم تقنية المعلومات في جامعتك.'),
        ],
      ),
    );
  }
}

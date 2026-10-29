import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'state/session_manager.dart';
import 'state/rubric_store.dart';
import 'theme/app_theme.dart';
import 'screens/case_input_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OsceSimulatorApp());
}

class OsceSimulatorApp extends StatelessWidget {
  const OsceSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()..load()),
        ChangeNotifierProvider(create: (_) => SessionManager()),
        ChangeNotifierProvider(create: (_) => RubricStore()..load()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'OSCE Simulation',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            builder: (context, child) => Directionality(
              textDirection:
                  settings.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
            home: const CaseInputScreen(),
          );
        },
      ),
    );
  }
}

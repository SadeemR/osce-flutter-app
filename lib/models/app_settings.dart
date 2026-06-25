import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English', '🇬🇧'),
  arabic('ar', 'العربية', '🇸🇦');

  const AppLanguage(this.code, this.displayName, this.flag);
  final String code;
  final String displayName;
  final String flag;

  static AppLanguage fromCode(String code) =>
      AppLanguage.values.firstWhere((l) => l.code == code,
          orElse: () => AppLanguage.english);
}

class AppSettings extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  String _apiBaseURL = 'https://osce-backend-production-de58.up.railway.app';
  int _preparationTime = 60;
  int _simulationTime = 300;

  AppLanguage get language => _language;
  String get apiBaseURL => _apiBaseURL;
  int get preparationTime => _preparationTime;
  int get simulationTime => _simulationTime;

  bool get isArabic => _language == AppLanguage.arabic;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(p.getString('language') ?? 'en');
    _apiBaseURL = p.getString('apiBaseURL') ??
        'https://osce-backend-production-de58.up.railway.app';
    _preparationTime = p.getInt('preparationTime') ?? 60;
    _simulationTime = p.getInt('simulationTime') ?? 300;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('language', lang.code);
  }

  Future<void> setApiBaseURL(String url) async {
    _apiBaseURL = url.trim();
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('apiBaseURL', _apiBaseURL);
  }

  Future<void> setPreparationTime(int seconds) async {
    _preparationTime = seconds;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('preparationTime', seconds);
  }

  Future<void> setSimulationTime(int seconds) async {
    _simulationTime = seconds;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('simulationTime', seconds);
  }
}

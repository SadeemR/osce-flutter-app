import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rubric_template.dart';

class RubricStore extends ChangeNotifier {
  static const _key = 'rubric_templates';
  List<RubricTemplate> _templates = [];

  List<RubricTemplate> get templates => _templates;

  RubricTemplate? get activeTemplate {
    if (_templates.isEmpty) return null;
    return _templates.firstWhere((t) => t.isDefault,
        orElse: () => _templates.first);
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _templates = list
            .map((e) => RubricTemplate.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _templates = [];
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(_templates.map((t) => t.toJson()).toList()));
  }

  Future<void> save(RubricTemplate template) async {
    _templates.add(template);
    await _persist();
    notifyListeners();
  }

  Future<void> delete(RubricTemplate template) async {
    _templates.removeWhere((t) => t.id == template.id);
    await _persist();
    notifyListeners();
  }

  Future<void> setDefault(RubricTemplate template) async {
    for (final t in _templates) {
      t.isDefault = t.id == template.id;
    }
    await _persist();
    notifyListeners();
  }
}

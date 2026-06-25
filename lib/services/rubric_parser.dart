import 'dart:convert';
import '../models/rubric_template.dart';

class RubricParser {
  static List<RubricCriterion> parse(String rawText) {
    final cleaned = rawText.trim();
    if (cleaned.isEmpty) return [];

    final json = _parseJson(cleaned);
    if (json != null && json.isNotEmpty) return json;

    final lines = cleaned
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final criteria = <RubricCriterion>[];
    for (final line in lines) {
      if (line.length < 3) continue;
      if (_isLikelyHeader(line)) continue;

      final delimited = _parseDelimitedLine(line);
      if (delimited != null) {
        criteria.add(delimited);
        continue;
      }
      final numbered = _parseNumberedLine(line);
      if (numbered != null) {
        criteria.add(numbered);
        continue;
      }
      final bullet = _parseBulletLine(line);
      if (bullet != null) criteria.add(bullet);
    }
    return criteria;
  }

  static List<RubricCriterion>? _parseJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(_dictToCriterion)
            .whereType<RubricCriterion>()
            .toList();
      }
      if (decoded is Map && decoded['criteria'] is List) {
        return (decoded['criteria'] as List)
            .whereType<Map<String, dynamic>>()
            .map(_dictToCriterion)
            .whereType<RubricCriterion>()
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static RubricCriterion? _dictToCriterion(Map<String, dynamic> dict) {
    const nameKeys = ['name', 'criterion', 'criteria', 'skill', 'category'];
    const descKeys = ['description', 'desc', 'details', 'definition'];

    String? name;
    for (final k in nameKeys) {
      final v = dict[k];
      if (v is String && v.isNotEmpty) {
        name = v;
        break;
      }
    }
    if (name == null) return null;

    var desc = '';
    for (final k in descKeys) {
      final v = dict[k];
      if (v is String) {
        desc = v;
        break;
      }
    }

    final weight = (dict['weight'] as num?)?.toDouble() ?? 1.0;
    final maxScore = (dict['maxScore'] as num?)?.toDouble() ??
        (dict['max_score'] as num?)?.toDouble() ??
        10.0;

    return RubricCriterion(
        name: name, description: desc, weight: weight, maxScore: maxScore);
  }

  static bool _isLikelyHeader(String line) {
    final lower = line.toLowerCase();
    const keywords = ['rubric', 'criteria', 'evaluation', 'scoring', 'table'];
    if (line == line.toUpperCase() && line.length < 30) return true;
    return keywords.any((k) => lower.startsWith(k) && line.length < 30);
  }

  static RubricCriterion? _parseDelimitedLine(String line) {
    for (final sep in ['|', '\t']) {
      final parts =
          line.split(sep).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        var weight = 1.0;
        if (parts.length >= 3) {
          weight = double.tryParse(parts[2]) ?? 1.0;
        }
        return RubricCriterion(
            name: parts[0], description: parts[1], weight: weight);
      }
    }
    return null;
  }

  static RubricCriterion? _parseNumberedLine(String line) {
    final m = RegExp(r'^\d+[\.\)]\s*(.+)').firstMatch(line);
    if (m == null) return null;
    return _parseNameAndDescription(m.group(1)!);
  }

  static RubricCriterion? _parseBulletLine(String line) {
    if (line.isEmpty) return null;
    if (!['-', '•', '*'].contains(line[0])) return null;
    return _parseNameAndDescription(line.substring(1).trim());
  }

  static RubricCriterion? _parseNameAndDescription(String text) {
    var weight = 1.0;
    var working = text;

    final wm = RegExp(r'\(weight[:\s]*([0-9.]+)\)').firstMatch(working);
    if (wm != null) {
      weight = double.tryParse(wm.group(1)!) ?? 1.0;
      working = working.replaceRange(wm.start, wm.end, '');
    }

    final parts = working.split(RegExp(r':')).map((p) => p.trim()).toList();
    if (parts.length >= 2) {
      return RubricCriterion(
          name: parts[0],
          description: parts.sublist(1).join(':'),
          weight: weight);
    } else if (parts.isNotEmpty && parts[0].length > 2) {
      return RubricCriterion(name: parts[0], description: '', weight: weight);
    }
    return null;
  }
}

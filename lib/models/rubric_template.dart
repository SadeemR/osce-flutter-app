import 'dart:convert';

class RubricCriterion {
  final String id;
  String name;
  String description;
  double weight;
  double maxScore;

  RubricCriterion({
    String? id,
    required this.name,
    this.description = '',
    this.weight = 1.0,
    this.maxScore = 10.0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  factory RubricCriterion.fromJson(Map<String, dynamic> j) => RubricCriterion(
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        weight: (j['weight'] as num?)?.toDouble() ?? 1.0,
        maxScore: (j['max_score'] as num?)?.toDouble() ?? 10.0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'weight': weight,
        'max_score': maxScore,
      };
}

class RubricTemplate {
  final String id;
  String name;
  String sourceFileName;
  String rawContent;
  String criteriaJSON;
  final DateTime createdAt;
  bool isDefault;

  RubricTemplate({
    String? id,
    required this.name,
    required this.sourceFileName,
    required this.rawContent,
    this.criteriaJSON = '[]',
    DateTime? createdAt,
    this.isDefault = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  List<RubricCriterion> get criteria {
    try {
      final decoded = jsonDecode(criteriaJSON);
      if (decoded is! List) return [];
      
      return decoded
          .map((e) => RubricCriterion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void updateCriteria(List<RubricCriterion> list) {
    criteriaJSON = jsonEncode(list.map((c) => c.toJson()).toList());
  }

  factory RubricTemplate.fromJson(Map<String, dynamic> j) => RubricTemplate(
        id: j['id'] as String?,
        name: j['name'] ?? '',
        sourceFileName: j['sourceFileName'] ?? '',
        rawContent: j['rawContent'] ?? '',
        criteriaJSON: j['criteriaJSON'] ?? '[]',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'])
            : null,
        isDefault: j['isDefault'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sourceFileName': sourceFileName,
        'rawContent': rawContent,
        'criteriaJSON': criteriaJSON,
        'createdAt': createdAt.toIso8601String(),
        'isDefault': isDefault,
      };
}
class EvaluationScore {
  final String id;
  final String criterionName;
  final double score;
  final double maxScore;
  final double weight;
  final String? feedback;

  EvaluationScore({
    String? id,
    required this.criterionName,
    required this.score,
    required this.maxScore,
    required this.weight,
    this.feedback,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  String get rating {
    final p = percentage;
    if (p >= 90) return 'Excellent';
    if (p >= 75) return 'Good';
    if (p >= 60) return 'Average';
    if (p >= 40) return 'Below Average';
    return 'Poor';
  }

  String get ratingColorName {
    final p = percentage;
    if (p >= 90) return 'green';
    if (p >= 75) return 'blue';
    if (p >= 60) return 'orange';
    return 'red';
  }
}

class EvaluationResult {
  final String id;
  final List<EvaluationScore> scores;
  final String? overallFeedback;
  final String rubricUsed;
  final DateTime timestamp;

  EvaluationResult({
    String? id,
    required this.scores,
    this.overallFeedback,
    required this.rubricUsed,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  double get totalScore {
    final totalWeight = scores.fold<double>(0, (s, e) => s + e.weight);
    if (totalWeight <= 0) return 0;
    final weightedSum = scores.fold<double>(0, (s, e) => s + e.score * e.weight);
    return weightedSum / totalWeight;
  }

  double get totalPercentage {
    final maxWeighted =
        scores.fold<double>(0, (s, e) => s + e.maxScore * e.weight);
    final actualWeighted =
        scores.fold<double>(0, (s, e) => s + e.score * e.weight);
    if (maxWeighted <= 0) return 0;
    return (actualWeighted / maxWeighted) * 100;
  }

  String get overallRating {
    final p = totalPercentage;
    if (p >= 90) return 'Excellent';
    if (p >= 75) return 'Good';
    if (p >= 60) return 'Average';
    if (p >= 40) return 'Below Average';
    return 'Poor';
  }

  factory EvaluationResult.fromApi(Map<String, dynamic> json) {
    final scoresMap = (json['scores'] is Map)
    ? json['scores'] as Map
    : {};
    final list = <EvaluationScore>[];
    scoresMap.forEach((name, detail) {
      final d = detail as Map<String, dynamic>;
      list.add(EvaluationScore(
        criterionName: _capitalize(name.toString()),
        score: (d['score'] as num?)?.toDouble() ?? 0,
        maxScore: (d['max_score'] as num?)?.toDouble() ?? 10,
        weight: (d['weight'] as num?)?.toDouble() ?? 1,
        feedback: d['feedback']?.toString(),
      ));
    });
    list.sort((a, b) => a.criterionName.compareTo(b.criterionName));
    return EvaluationResult(
      scores: list,
      overallFeedback: json['overall_feedback']?.toString(),
      rubricUsed: json['rubric_used']?.toString() ?? 'Custom Rubric',
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

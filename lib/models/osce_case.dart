/// The kind of OSCE station. Changes how the AI patient behaves.
enum StationType {
  badNews('bad_news'),
  historyTaking('history_taking');

  const StationType(this.code);
  final String code;
}

class OsceCase {
  StationType stationType;
  String patientInfo;
  String complaint;
  String results;
  String situation;

  /// Details only the AI patient sees — revealed when the student asks.
  String hiddenInfo;

  String? attachedFileName;
  String? attachedFileText;

  String language;
  String aiGeneratedPrompt;
  final DateTime createdAt;

  OsceCase({
    this.stationType = StationType.badNews,
    this.patientInfo = '',
    this.complaint = '',
    this.results = '',
    this.situation = '',
    this.hiddenInfo = '',
    this.attachedFileName,
    this.attachedFileText,
    this.language = 'en',
    this.aiGeneratedPrompt = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasContent {
    final manual = patientInfo.trim().isNotEmpty ||
        complaint.trim().isNotEmpty ||
        results.trim().isNotEmpty ||
        situation.trim().isNotEmpty ||
        hiddenInfo.trim().isNotEmpty;

    final file = (attachedFileText?.trim().isNotEmpty ?? false);

    return manual || file;
  }

  String get fullDescription {
    final parts = <String>[];

    if (patientInfo.trim().isNotEmpty) {
      parts.add('Patient: $patientInfo');
    }

    if (complaint.trim().isNotEmpty) {
      parts.add('Complaint: $complaint');
    }

    if (results.trim().isNotEmpty) {
      parts.add('Results: $results');
    }

    if (situation.trim().isNotEmpty) {
      parts.add('Situation: $situation');
    }

    if (attachedFileText?.trim().isNotEmpty ?? false) {
      parts.add('Additional Case File:\n$attachedFileText');
    }

    return parts.join('\n\n');
  }

  Map<String, dynamic> get apiPayload => {
        'station_type': stationType.code,
        if (patientInfo.isNotEmpty) 'patient': patientInfo,
        if (complaint.isNotEmpty) 'complaint': complaint,
        if (results.isNotEmpty) 'results': results,
        if (situation.isNotEmpty) 'situation': situation,
        if (hiddenInfo.isNotEmpty) 'hidden_info': hiddenInfo,
        if (attachedFileText?.isNotEmpty ?? false)
          'attached_text': attachedFileText,
        if (attachedFileName?.isNotEmpty ?? false)
          'attached_name': attachedFileName,
        'language': language,
      };

  static OsceCase get empty => OsceCase();

  static OsceCase get sample => OsceCase(
        patientInfo: '10-year-old child',
        complaint: 'Difficulty breathing, nausea, weakness, dizziness',
        results: 'covid-19',
        situation: "Discuss the diagnosis with the child's parents.",
      );
}

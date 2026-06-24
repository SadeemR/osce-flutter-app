import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/osce_case.dart';
import '../models/rubric_template.dart';
import '../models/evaluation_result.dart';

/// مدير الجلسة والحالة العامة — محوّل من SessionManager.swift
class SessionManager extends ChangeNotifier {
  OsceCase currentCase = OsceCase.empty;
  String sessionId = ''; // معرّف الجلسة الخاص بهذا الطالب
  List<ChatMessage> messages = [];
  EvaluationResult? evaluationResult;
  DateTime? sessionStartTime;
  int studentNumber = 0;

  List<int>? caseFileData;
  String? caseFileName;
  RubricTemplate? activeRubricTemplate;

  void reset() {
    currentCase = OsceCase.empty;
    sessionId = '';
    messages = [];
    evaluationResult = null;
    sessionStartTime = null;
    caseFileData = null;
    caseFileName = null;
    notifyListeners();
  }

  void addMessage(ChatMessage msg) {
    messages = [...messages, msg];
    notifyListeners();
  }

  void replaceMessage(String id, ChatMessage newMsg) {
    final updated = messages.map((m) => m.id == id ? newMsg : m).toList();
    messages = updated;
    notifyListeners();
  }

  void removeMessage(String id) {
    messages = messages.where((m) => m.id != id).toList();
    notifyListeners();
  }

  void removeLoadingMessages() {
    messages = messages.where((m) => !m.isLoading).toList();
    notifyListeners();
  }

  List<ChatMessage> get doctorMessages =>
      messages.where((m) => m.sender == MessageSender.doctor).toList();

  String get activeRubricText => activeRubricTemplate?.rawContent ?? '';

  void touch() => notifyListeners();
}

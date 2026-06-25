import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/osce_case.dart';
import '../models/rubric_template.dart';
import '../models/evaluation_result.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class CaseStartResult {
  final String initialMessage;
  final String sessionId;
  CaseStartResult({required this.initialMessage, required this.sessionId});
}

class ApiService {
  ApiService(this.baseURL);
  final String baseURL;

  Uri _url(String path) {
    final u = Uri.tryParse('$baseURL$path');
    if (u == null) throw ApiException('عنوان الخادم غير صالح. تحقق من الإعدادات.');
    return u;
  }

  void _validate(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('خطأ من الخادم ${res.statusCode}: ${res.body}');
    }
  }

  /// يولّد رسالة افتتاحية مناسبة بناءً على بيانات الحالة واللغة
  static String _buildFallbackGreeting(OsceCase c) {
    final isAr = c.language == 'ar';
    final patient = c.patientInfo.trim();
    final complaint = c.complaint.trim();

    if (patient.isEmpty && complaint.isEmpty) {
      return isAr
          ? 'السلام عليكم دكتور، أنا هنا لأن عندي مشكلة...'
          : "Hello Doctor, I need your help with something...";
    }

    if (isAr) {
      final patientPart = patient.isNotEmpty ? ' بخصوص $patient' : '';
      final complaintPart = complaint.isNotEmpty ? '، عنده/عندها $complaint' : '';
      return 'السلام عليكم دكتور، جيت اليوم$patientPart$complaintPart. ممكن تساعدني؟';
    } else {
      final patientPart = patient.isNotEmpty ? ' regarding $patient' : '';
      final complaintPart = complaint.isNotEmpty ? ' who has $complaint' : '';
      return "Hello Doctor, I'm here today$patientPart$complaintPart. Can you help me?";
    }
  }

  static String _generateSessionId() {
    final rand = Random.secure();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = List.generate(6, (_) => rand.nextInt(36).toRadixString(36)).join();
    return 'sess_${ts}_$suffix';
  }

  // ===== تحديث الحالة =====
  Future<CaseStartResult> updateCase(OsceCase c,
      {List<int>? fileBytes, String? fileName}) async {
    final sessionId = _generateSessionId();

    if (fileBytes != null && fileName != null) {
      // رفع multipart
      final req = http.MultipartRequest('POST', _url('/update-case-file'));
      c.apiPayload.forEach((k, v) => req.fields[k] = '$v');
      req.files.add(http.MultipartFile.fromBytes('file', fileBytes,
          filename: fileName));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _validate(res);
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      return CaseStartResult(
        initialMessage: (j['initial_message'] as String?) ?? _buildFallbackGreeting(c),
        sessionId: (j['session_id'] as String?) ?? sessionId,
      );
    } else {
      // رفع JSON
      final res = await http.post(_url('/update-case'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(c.apiPayload));
      _validate(res);
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      return CaseStartResult(
        initialMessage: (j['initial_message'] as String?) ?? _buildFallbackGreeting(c),
        sessionId: (j['session_id'] as String?) ?? sessionId,
      );
    }
  }

  // ===== المحادثة =====
  Future<String> sendMessage(String sessionId, String message) async {
    final res = await http.post(_url('/chat'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'session_id': sessionId, 'message': message}));
    _validate(res);
    final j = jsonDecode(utf8.decode(res.bodyBytes));
    return (j['reply'] as String?) ?? '';
  }

  // ===== التقييم =====
  Future<EvaluationResult> evaluate(
      {required String sessionId,
      required String rubricText,
      List<ChatMessage> messages = const []}) async {
    final msgList = messages
        .where((m) => !m.isLoading)
        .map((m) => {'sender': m.sender.raw, 'text': m.text})
        .toList();
    final res = await http.post(_url('/evaluate'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'rubric_text': rubricText,
          'messages': msgList
        }));
    _validate(res);
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return EvaluationResult.fromApi(j);
  }

  Future<List<RubricCriterion>> parseRubricFile(
      {required List<int> bytes, required String fileName}) async {
    final req = http.MultipartRequest('POST', _url('/parse-rubric'));
    req.files
        .add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _validate(res);
    final j = jsonDecode(utf8.decode(res.bodyBytes));
    final criteria = (j['criteria'] as List?) ?? [];
    return criteria
        .map((e) => RubricCriterion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===== حفظ نتيجة الطالب =====
  Future<void> saveResult({
    required String sessionId,
    required int studentNumber,
    required EvaluationResult result,
  }) async {
    final scoresDict = <String, dynamic>{};
    for (final s in result.scores) {
      scoresDict[s.criterionName] = {
        'score': s.score,
        'max_score': s.maxScore,
        'weight': s.weight,
        'feedback': s.feedback ?? '',
      };
    }
    try {
      await http.post(_url('/save-result/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'session_id': sessionId,
            'student_number': studentNumber,
            'overall_score': result.totalPercentage,
            'overall_rating': result.overallRating,
            'overall_feedback': result.overallFeedback ?? '',
            'scores': scoresDict,
            'rubric_used': result.rubricUsed,
          }));
    } catch (_) {/* الحفظ اختياري */}
  }

  // ===== تسجيل بيانات الطالب =====
  Future<void> sendStudent({required int number, required double grade}) async {
    try {
      await http.post(_url('/students/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'number': number, 'grade': grade}));
    } catch (_) {}
  }

  Future<String?> generatePrompt(OsceCase c) async {
    try {
      final res = await http.post(_url('/students/generate-prompt/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'patient': c.patientInfo,
            'complaint': c.complaint,
            'results': c.results,
            'situation': c.situation,
          }));
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return j['prompt'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ===== فحص الاتصال =====
  Future<bool> testConnection() async {
    try {
      final res = await http.get(_url('/health'));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
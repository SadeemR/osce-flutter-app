import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// أنواع الملفات المدعومة — محوّل من SupportedFileType
enum SupportedFileType {
  pdf,
  docx,
  doc,
  txt,
  json,
  xlsx,
  xls,
  csv;

  static SupportedFileType? fromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return pdf;
      case 'docx':
        return docx;
      case 'doc':
        return doc;
      case 'txt':
        return txt;
      case 'json':
        return json;
      case 'xlsx':
        return xlsx;
      case 'xls':
        return xls;
      case 'csv':
        return csv;
      default:
        return null;
    }
  }

  /// هل يمكن استخراج النص محليًا؟ وإلا يُرفع للباك إند
  bool get canExtractLocally {
    switch (this) {
      case pdf:
      case txt:
      case json:
      case csv:
        return true;
      default:
        return false;
    }
  }

  // الصيغ المدعومة فعليًا (تُستخرج محليًا): PDF, TXT, CSV, JSON
  static const allowedExtensions = ['pdf', 'txt', 'json', 'csv'];
}

/// ملف بعد المعالجة — محوّل من ProcessedFile
class ProcessedFile {
  final String fileName;
  final String extractedText;
  final List<int> rawData;
  final SupportedFileType fileType;
  final bool needsServerParsing;

  ProcessedFile({
    required this.fileName,
    required this.extractedText,
    required this.rawData,
    required this.fileType,
    required this.needsServerParsing,
  });
}

class FileProcessorException implements Exception {
  final String message;
  FileProcessorException(this.message);
  @override
  String toString() => message;
}

/// معالج الملفات — محوّل من FileProcessor.swift
class FileProcessor {
  static ProcessedFile process({
    required String fileName,
    required List<int> bytes,
    required String extension,
  }) {
    final fileType = SupportedFileType.fromExtension(extension);
    if (fileType == null) {
      throw FileProcessorException('نوع الملف غير مدعوم.');
    }
    if (bytes.isEmpty) {
      throw FileProcessorException('الملف فارغ.');
    }

    if (fileType.canExtractLocally) {
      String text = '';
      switch (fileType) {
        case SupportedFileType.pdf:
          text = _extractPdf(bytes) ?? '';
          break;
        case SupportedFileType.txt:
        case SupportedFileType.csv:
          text = _extractPlainText(bytes) ?? '';
          break;
        case SupportedFileType.json:
          text = _extractJson(bytes) ?? '';
          break;
        default:
          break;
      }
      return ProcessedFile(
        fileName: fileName,
        extractedText: text,
        rawData: bytes,
        fileType: fileType,
        needsServerParsing: text.trim().isEmpty,
      );
    }

    // Word / Excel → الباك إند
    return ProcessedFile(
      fileName: fileName,
      extractedText: '',
      rawData: bytes,
      fileType: fileType,
      needsServerParsing: true,
    );
  }

  static String? _extractPdf(List<int> bytes) {
    try {
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();
      return text.trim().isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  static String? _extractPlainText(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return null;
      }
    }
  }

  static String? _extractJson(List<int> bytes) {
    try {
      final obj = jsonDecode(utf8.decode(bytes));
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return _extractPlainText(bytes);
    }
  }
}

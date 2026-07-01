import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/rubric_template.dart';
import '../services/api_service.dart';
import '../services/file_processor.dart';
import '../services/rubric_parser.dart';
import '../state/rubric_store.dart';
import '../state/session_manager.dart';
import '../theme/app_theme.dart';

class RubricLibraryScreen extends StatefulWidget {
  const RubricLibraryScreen({super.key});

  @override
  State<RubricLibraryScreen> createState() => _RubricLibraryScreenState();
}

class _RubricLibraryScreenState extends State<RubricLibraryScreen> {
  bool _processing = false;

  Future<void> _pickAndProcess() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupportedFileType.allowedExtensions,
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;
    final f = res.files.single;

    ProcessedFile processed;
    try {
      processed = FileProcessor.process(
          fileName: f.name, bytes: f.bytes!, extension: f.extension ?? '');
    } catch (e) {
      _showError(e.toString());
      return;
    }

    final defaultName = f.name
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    final nameCtrl = TextEditingController(text: defaultName);

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('سمِّ ورقة التقييم'),
        content: TextField(
          controller: nameCtrl,
          decoration:
              const InputDecoration(hintText: 'مثال: أم القرى - أطفال'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _processing = true);
    final store = context.read<RubricStore>();
    final apiBaseUrl = context.read<AppSettings>().apiBaseURL;
    try {
      var extractedText = processed.extractedText;
      List<RubricCriterion> criteria;
      if (processed.needsServerParsing) {
        final api = ApiService(apiBaseUrl);
        criteria = await api.parseRubricFile(
            bytes: processed.rawData, fileName: processed.fileName);
        extractedText =
            criteria.map((c) => '- ${c.name}: ${c.description}').join('\n');
      } else {
        criteria = RubricParser.parse(extractedText);
      }

      final template = RubricTemplate(
        name: nameCtrl.text.trim().isEmpty
            ? processed.fileName
            : nameCtrl.text.trim(),
        sourceFileName: processed.fileName,
        rawContent: extractedText,
      );
      template.updateCriteria(criteria);
      if (store.templates.isEmpty) template.isDefault = true;
      await store.save(template);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RubricStore>();
    final session = context.read<SessionManager>();

    return Scaffold(
      backgroundColor: AppColors.purpleDeep,
      appBar: AppBar(
        title: const Text('Evaluation Rubrics'),
        actions: [
          IconButton(
              onPressed: _pickAndProcess, icon: const Icon(Icons.add)),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _uploadButton(),
              const SizedBox(height: 20),
              if (store.templates.isEmpty)
                _emptyState()
              else ...[
                const Text('أوراق التقييم المحفوظة',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyan)),
                const SizedBox(height: 8),
                ...store.templates.map((t) => _rubricRow(t, store, session)),
                const SizedBox(height: 8),
                const Text(
                    'اضغط على ورقة لتفعيلها. اسحب لليمين للحذف، أو استخدم زر النجمة للتعيين كافتراضية.',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ],
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('جارٍ معالجة الملف…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _uploadButton() {
    return InkWell(
      onTap: _pickAndProcess,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.upload_file, color: AppColors.cyan),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رفع ورقة تقييم',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('PDF, TXT, CSV, JSON',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 40, color: Colors.black38),
          SizedBox(height: 12),
          Text('لا توجد أوراق تقييم بعد',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('ارفع ورقة تقييم جامعتك للبدء.',
              style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _rubricRow(
      RubricTemplate t, RubricStore store, SessionManager session) {
    final active = store.activeTemplate?.id == t.id;
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: AppColors.ratingRed,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => store.delete(t),
      child: InkWell(
        onTap: () {
          store.setDefault(t);
          session.activeRubricTemplate = t;
          session.touch();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardCream,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(color: AppColors.mint, width: 1.5)
                : Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: active
                        ? AppColors.mint.withValues(alpha: 0.2)
                        : AppColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(active ? Icons.verified : Icons.description_outlined,
                    color: active ? AppColors.cyan : Colors.black45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                            child: Text(t.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500))),
                        if (t.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.purple,
                                borderRadius: BorderRadius.circular(100)),
                            child: const Text('DEFAULT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lime)),
                          ),
                        ],
                      ],
                    ),
                    Text('${t.criteria.length} معيار · ${t.sourceFileName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    Text(DateFormat.yMMMd().add_jm().format(t.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38)),
                  ],
                ),
              ),
              if (!t.isDefault)
                IconButton(
                  tooltip: 'تعيين كافتراضية',
                  onPressed: () => store.setDefault(t),
                  icon: const Icon(Icons.star_outline, color: AppColors.cyan),
                ),
              if (active)
                const Icon(Icons.radio_button_checked,
                    color: AppColors.mint),
            ],
          ),
        ),
      ),
    );
  }
}
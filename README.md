# OSCE Simulator — نسخة Flutter

تطبيق محاكاة محطات OSCE لمهارات التواصل بين الطبيب والمريض، **محوَّل بالكامل من SwiftUI إلى Flutter** مع الحفاظ على كل الوظائف والشكل (لوحة Apricot & Burgundy).

## الميزات (مطابقة للنسخة الأصلية)
- شاشة إدخال الحالة: ٤ حقول (المريض، الشكوى، النتائج، الموقف) + إرفاق ملف (PDF/Word/Excel/TXT/JSON) + معلومات الطالب + اختيار ورقة التقييم.
- مبدّل اللغة (عربي/إنجليزي) في الترويسة، مع اتجاه RTL تلقائي.
- شاشة التحضير بمؤقّت دائري.
- شاشة المحادثة الحية مع مؤقّت ٥ دقائق وفقاعات حوار.
- شاشة التقييم الديناميكية: حلقة الدرجة الكلية، معايير قابلة للتوسيع بأوزان، تغذية راجعة، ملخص الجلسة، مشاركة النتائج.
- مكتبة أوراق التقييم: رفع وحفظ قوالب الجامعة محليًا، تعيين افتراضي، حذف.
- شاشة الإعدادات: مؤقّتات، لغة، سياسة خصوصية.

## الاتصال بالباك إند
التطبيق يتصل بنفس باك إندك الحالي (Flask على Railway) دون أي تغيير في الخادم. العنوان مضبوط افتراضيًا على:
`https://web-production-b73a5.up.railway.app`
ويمكن تغييره برمجيًا في `lib/models/app_settings.dart`.

الـ endpoints المستخدمة: `/update-case`, `/update-case-file`, `/chat`, `/evaluate`, `/parse-rubric`, `/students/`, `/students/generate-prompt/`, `/save-result/`, `/health`.

## بنية المشروع
```
lib/
├── main.dart                      # نقطة الدخول + الثيم + التنقل (OSCESimulatorApp + RootView)
├── theme/app_theme.dart           # لوحة الألوان (AppTheme.swift)
├── models/                        # النماذج
│   ├── app_settings.dart          # AppSettings + AppLanguage
│   ├── chat_message.dart          # ChatMessage
│   ├── osce_case.dart             # OSCECase
│   ├── rubric_template.dart       # RubricTemplate + RubricCriterion
│   └── evaluation_result.dart     # EvaluationResult + EvaluationScore
├── services/                      # الخدمات
│   ├── api_service.dart           # APIService (الاتصال بالباك إند)
│   ├── file_processor.dart        # FileProcessor (استخراج نص الملفات)
│   └── rubric_parser.dart         # RubricParser (تحليل ورقة التقييم)
├── state/                         # إدارة الحالة (Provider)
│   ├── session_manager.dart       # SessionManager
│   └── rubric_store.dart          # RubricStore (تخزين محلي بدل SwiftData)
├── screens/                       # الشاشات
│   ├── case_input_screen.dart     # CaseInputView
│   ├── preparation_screen.dart    # PreparationView
│   ├── simulation_screen.dart     # SimulationView (+ViewModel)
│   ├── evaluation_screen.dart     # EvaluationView (+CriterionRow)
│   ├── rubric_library_screen.dart # RubricLibraryView
│   └── settings_screen.dart       # SettingsView + PrivacyPolicyView
└── widgets/common.dart            # CardContainer + CaseFormField
```

## ملاحظات التحويل (Swift → Flutter)
- `ObservableObject` / `@EnvironmentObject` → `ChangeNotifier` + حزمة `provider`.
- `@AppStorage` و `SwiftData` → `shared_preferences` (تخزين JSON محلي).
- `PDFKit` → `syncfusion_flutter_pdf` لاستخراج نص PDF محليًا.
- `fileImporter` → `file_picker`.
- `UIActivityViewController` → `share_plus`.
- `NavigationStack` → `Navigator` العادي في Flutter.

## التشغيل
```bash
flutter pub get
flutter run
```
ملاحظة: عند أول تشغيل في مجلد جديد، نفّذ `flutter create .` لتوليد مجلدات المنصات (ios/android) إن لم تكن موجودة.

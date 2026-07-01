# OSCE Simulation — دليل التشغيل

محاكي محطات OSCE لمهارات التواصل بين الطبيب والمريض.

---

## المتطلبات قبل البدء

| البرنامج | الرابط |
|---------|--------|
| Flutter SDK (النسخة 3.3 أو أحدث) | https://docs.flutter.dev/get-started/install |
| Git | https://git-scm.com/downloads |
| متصفح Chrome (للتشغيل على الويب) | https://www.google.com/chrome |

---

## خطوات التشغيل

### 1. تثبيت Flutter

اتبعي تعليمات الموقع الرسمي حسب نظام تشغيلك (Mac / Windows):
👉 https://docs.flutter.dev/get-started/install

بعد التثبيت تحققي أن كل شيء سليم:

```bash
flutter doctor
```

---

### 2. تحميل المشروع من GitHub

افتحي الترمينال وشغّلي:

```bash
git clone https://github.com/SadeemR/osce-flutter-app.git
cd osce-flutter-app
```

---

### 3. تثبيت المكتبات

```bash
flutter pub get
```

---

### 4. تشغيل التطبيق

**على المتصفح (Chrome):**
```bash
flutter run -d chrome
```

**على الكمبيوتر مباشرة (Mac):**
```bash
flutter run -d macos
```

**على الكمبيوتر مباشرة (Windows):**
```bash
flutter run -d windows
```

---

## في حال وجود مشاكل

**مشكلة: `flutter` غير معروف كأمر**
تأكدي أن Flutter مضاف لـ PATH — اتبعي تعليمات الموقع الرسمي حسب نظامك.

**مشكلة: `flutter pub get` يعطي خطأ**
```bash
flutter clean
flutter pub get
```

**مشكلة: Chrome لا يفتح**
```bash
flutter run -d web-server
```
ثم افتحي المتصفح على: `http://localhost:8080`

---

## ملاحظات

- التطبيق يحتاج اتصال بالإنترنت لعمل المحاكاة
- يدعم اللغتين العربية والإنجليزية
- يمكن رفع ملف PDF للحالة أو إدخال البيانات يدوياً

---

## تفاصيل المشروع

تطبيق محاكاة محطات OSCE، **محوَّل بالكامل من SwiftUI إلى Flutter** مع الحفاظ على كل الوظائف.

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

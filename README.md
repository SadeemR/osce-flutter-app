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
ياً

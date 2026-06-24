/// نصوص التطبيق — عربي وإنجليزي
class AppStrings {
  final bool isArabic;
  const AppStrings(this.isArabic);

  // ===== Case Input Screen =====
  String get caseFile => isArabic ? 'ملف الحالة' : 'Case File';
  String get attachFile => isArabic ? 'إرفاق ملف الحالة' : 'Attach Case File';
  String get fileFormats => isArabic ? 'PDF · TXT · CSV · JSON' : 'PDF · TXT · CSV · JSON';
  String get serverParsed => isArabic ? 'سيُحلَّل بواسطة الخادم' : 'Will be parsed by server';
  String get locallyExtracted => isArabic ? 'استُخرج النص محليًا' : 'Text extracted locally';
  String get orFillManually => isArabic ? 'أو املأ الحقول أدناه يدويًا (يمكنك فعل الاثنين).' : 'Or fill in the fields below manually (you can do both).';
  String get manualInput => isArabic ? 'الإدخال اليدوي' : 'Manual Input';
  String get optionalWithFile => isArabic ? 'اختياري عند إرفاق ملف' : 'Optional when file attached';
  String get patient => isArabic ? 'المريض' : 'Patient';
  String get patientHint => isArabic ? 'مثال: طفل عمره ١٠ سنوات' : 'Example: 10-year-old child';
  String get complaint => isArabic ? 'الشكوى' : 'Complaint';
  String get complaintHint => isArabic ? 'مثال: إسهال مزمن وألم في البطن' : 'Example: Chronic diarrhea and abdominal pain';
  String get results => isArabic ? 'النتائج' : 'Results';
  String get resultsHint => isArabic ? 'مثال: الخزعة متوافقة مع حساسية القمح' : 'Example: Biopsy consistent with wheat allergy';
  String get situation => isArabic ? 'الموقف' : 'Situation';
  String get situationHint => isArabic ? 'مثال: الأم لا تعلم بالتشخيص وقلقة' : 'Example: Mother unaware of diagnosis and anxious';
  String get loadSample => isArabic ? 'تحميل حالة تجريبية' : 'Load Sample Case';
  String get rubricSheet => isArabic ? 'ورقة التقييم' : 'Evaluation Rubric';
  String get addRubric => isArabic ? 'إضافة ورقة تقييم' : 'Add Evaluation Rubric';
  String get changeRubric => isArabic ? 'تغيير' : 'Change';
  String get noRubricNote => isArabic
      ? 'بدون ورقة تقييم سيختار الذكاء الاصطناعي معاييره بنفسه.'
      : 'Without a rubric, the AI will choose its own criteria.';
  String get studentInfo => isArabic ? 'معلومات الطالب' : 'Student Information';
  String get studentNumber => isArabic ? 'رقم الطالب' : 'Student Number';
  String get studentNumberHint => isArabic ? 'مثال: 1001' : 'Example: 1001';
  String get grade => isArabic ? 'الدرجة' : 'Grade';
  String get gradeHint => isArabic ? 'مثال: 95.5' : 'Example: 95.5';
  String get startExam => isArabic ? 'بدء الاختبار' : 'Start Exam';
  String get initializing => isArabic ? 'جارٍ التهيئة…' : 'Initializing…';
  String get errorTitle => isArabic ? 'خطأ' : 'Error';
  String get ok => isArabic ? 'حسنًا' : 'OK';
  String get fillAtLeastOne => isArabic
      ? 'الرجاء تعبئة حقل واحد على الأقل أو إرفاق ملف.'
      : 'Please fill in at least one field or attach a file.';

  // ===== Preparation Screen =====
  String get preparationPhase => isArabic ? 'مرحلة التحضير' : 'Preparation Phase';
  String get caseInformation => isArabic ? 'معلومات الحالة' : 'Case Information';
  String get patientLabel => isArabic ? 'Patient' : 'Patient';
  String get complaintLabel => isArabic ? 'Complaint' : 'Complaint';
  String get resultsLabel => isArabic ? 'Results' : 'Results';
  String get situationLabel => isArabic ? 'Situation' : 'Situation';
  String get fileLabel => isArabic ? 'File' : 'File';
  String get requiredTasks => isArabic ? 'المهام المطلوبة (٥ دقائق)' : 'Required Tasks (5 minutes)';
  String get task1 => isArabic
      ? '١. أبلغ المريض/المرافق بالتشخيص بتعاطف.'
      : '1. Break the news of the diagnosis with empathy.';
  String get task2 => isArabic
      ? '٢. اشرح خطة العلاج وأجب على الأسئلة.'
      : "2. Explain management and answer the parent's questions.";
  String get prepNote => isArabic
      ? 'لديك دقيقة واحدة للتحضير قبل بدء الجلسة.'
      : 'You have one minute to prepare before the session begins.';
  String get preparationTime => isArabic ? 'وقت التحضير' : 'Preparation Time';
  String get preparationPhaseLabel => isArabic ? 'مرحلة التحضير' : 'Preparation Phase';
  String get skip => isArabic ? 'تخطي ⏭' : 'Skip ⏭';

  // ===== Simulation Screen =====
  String get osceSimulation => isArabic ? 'محاكاة OSCE' : 'OSCE Simulation';
  String get taskTimeRemaining => isArabic ? 'الوقت المتبقي: ' : 'Task Time Remaining: ';
  String get testPhase => isArabic ? 'مرحلة الاختبار' : 'Test Phase';
  String get endSession => isArabic ? 'إنهاء الجلسة' : 'End Session';
  String get typeResponse => isArabic ? 'اكتب ردك هنا...' : 'Type your response here…';
  String get sessionEndedEval => isArabic
      ? 'انتهت الجلسة — جارٍ إعداد التقييم…'
      : 'Session ended — generating evaluation…';
  String get errorPrefix => isArabic ? 'خطأ: ' : 'Error: ';

  // ===== Evaluation Screen =====
  String get evaluationResults => isArabic ? 'نتائج التقييم' : 'Evaluation Results';
  String get analyzingPerformance => isArabic ? 'جارٍ تحليل أدائك…' : 'Analyzing your performance…';
  String get aiAnalyzing => isArabic
      ? 'يقيّم الذكاء الاصطناعي إجاباتك وفق معايير ورقة التقييم.'
      : 'The AI is evaluating your responses against the rubric criteria.';
  String get failedToLoad => isArabic ? 'تعذّر تحميل النتائج' : 'Failed to load results';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get evaluationCriteria => isArabic ? 'معايير التقييم' : 'Evaluation Criteria';
  String get aiFeedback => isArabic ? 'ملاحظات الذكاء الاصطناعي' : 'AI Feedback';
  String get sessionSummary => isArabic ? 'ملخص الجلسة' : 'Session Summary';
  String get rubricLabel => isArabic ? 'ورقة التقييم' : 'Rubric';
  String get messagesLabel => isArabic ? 'الرسائل' : 'Messages';
  String get durationLabel => isArabic ? 'المدة' : 'Duration';
  String get startNewSession => isArabic ? 'بدء جلسة جديدة' : 'Start New Session';
  String get shareResults => isArabic ? 'مشاركة النتائج' : 'Share Results';
  String get criteria => isArabic ? 'المعايير' : 'Criteria';
  String get duration => isArabic ? 'المدة' : 'Duration';
  String get messages => isArabic ? 'الرسائل' : 'Messages';

  // ===== Rubric Library =====
  String get evaluationRubrics => isArabic ? 'أوراق التقييم' : 'Evaluation Rubrics';
  String get uploadRubric => isArabic ? 'رفع ورقة تقييم' : 'Upload Rubric';
  String get savedRubrics => isArabic ? 'أوراق التقييم المحفوظة' : 'Saved Rubrics';
  String get noRubrics => isArabic ? 'لا توجد أوراق تقييم بعد' : 'No rubrics yet';
  String get uploadToStart => isArabic ? 'ارفع ورقة تقييم جامعتك للبدء.' : 'Upload your university rubric to get started.';
  String get nameRubric => isArabic ? 'سمِّ ورقة التقييم' : 'Name the Rubric';
  String get nameHint => isArabic ? 'مثال: أم القرى - أطفال' : 'Example: UQU - Pediatrics';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get processingFile => isArabic ? 'جارٍ معالجة الملف…' : 'Processing file…';
  String get rubricHint => isArabic
      ? 'اضغط على ورقة لتفعيلها. اسحب لليمين للحذف.'
      : 'Tap a rubric to activate it. Swipe right to delete.';
}

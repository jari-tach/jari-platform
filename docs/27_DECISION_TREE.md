# SAEQ — Decision Tree

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Review Date:** 2026-07-23  
> **Next Review:** 2027-01-23  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## شجرة القرارات

استخدم هذه الشجرة للعثور على الوثيقة الصحيحة عندما تحتاج إلى تعديل جزء معين من المشروع.

---

### إذا أردت تعديل قاعدة البيانات ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| تصميم قاعدة البيانات العام | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| جدول معين (orders، drivers، deliveries) | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| DAO (Data Access Object) | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| مزامنة البيانات (Cache-First، Write-Through) | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md)، [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| ترحيل قاعدة البيانات | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| فهرس المنتجات (جداول products، categories، brands) | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| سوق الجملة (جداول suppliers، traders، wholesale_orders) | [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) |
| إضافة جدول جديد | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md)، [35_DATABASE_INDEX.md](./35_DATABASE_INDEX.md) |

---

### إذا أردت تعديل API ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| إعداد Dio (الوقت المتاح، الترؤوس) | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| Interceptors (Auth، Logging، Retry، Error) | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| عميل API (Retrofit) — نقاط النهاية | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| Serialization / Deserialization | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| إصدار واجهة برمجة التطبيقات | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| حدود المعدل | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| إضافة نقطة API جديدة | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md)، [34_API_INDEX.md](./34_API_INDEX.md) |
| الأمان (HTTPS، Certificate Pinning) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |

---

### إذا أردت تعديل Theme ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| الألوان (primary، secondary، dark mode) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| الخطوط (GoogleFonts Tajawal) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| الأزرار (Primary، Secondary، Text، Icon) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| البطاقات (SectionCard، ElevatedCard) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| الحقول (TextInput، PasswordInput) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| التنبيهات والرسائل (SnackBar، Dialog) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| الأيقونات | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| الحركة (Transitions، Durations) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| الوضع الليلي | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| إرشادات Flutter | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |

---

### إذا أردت تعديل Authentication ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| استراتيجية المصادقة (JWT، Refresh Tokens) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| التخزين الآمن (flutter_secure_storage) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| المصادقة البيومترية (Face ID، Touch ID) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| إدارة الجلسات (Session Timeout) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| التفويض (RBAC — Roles) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| Auth Interceptor | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| تسجيل الدخول / التسجيل / إعادة تعيين كلمة المرور | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| نظام وصل (Nafath) | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |

---

### إذا أردت تعديل Error Handling ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| التسلسل الهرمي للأخطاء (Exception، Failure) | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| تدفق الاستثناءات (Presentation ← Domain ← Data) | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| رسائل الخطأ (عربي/إنجليزي) | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| عرض الأخطاء (SnackBar، Dialog) | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| استراتيجيات التعافي (Retry، Redirect) | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |

---

### إذا أردت تعديل Testing ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| هرم الاختبار (Unit، Widget، Integration) | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |
| تنظيم الاختبارات (مجلدات) | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |
| المحاكاة (mocktail) | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |
| تغطية الاختبار | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |
| أفضل ممارسات الاختبار | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |

---

### إذا أردت تعديل Offline ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| اكتشاف الاتصال (NetworkInfo) | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| استراتيجية القراءة (Cache-First) | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| استراتيجية الكتابة (Queue-and-Sync) | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| مؤشرات UI غير المتصل | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| حل النزاعات | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |

---

### إذا أردت تعديل Deployment ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| خط معالجة CI | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| خط معالجة CD | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| بيئات العمل (dev، staging، prod) | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| نكهات البناء (Flavors) | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| بوابات الجودة | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| إصدار البرنامج (Semantic Versioning) | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |

---

### إذا أردت تعديل Logging ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| مستويات التسجيل (debug، info، warning، error، fatal) | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| إعداد Logger | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| السياق (Context) | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| ما يتم تسجيله وما لا يتم | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| التسجيل عن بُعد | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| مدة الاحتفاظ بالسجلات | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |

---

### إذا أردت تعديل Coding Standards ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| اللغة والأدوات (Dart، SDK) | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| قواعق التنسيق (طول السطر، المسافة) | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| قواعق التوثيق (dartdoc) | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| جودة الكود (SOLID، DRY، KISS) | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| إدارة الأخطاء | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| الاختبارات | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |
| إدارة الحالة (Riverpod) | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| التنقل (GoRouter) | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |

---

### إذا أردت تعديل Folder Structure ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| الهيكل العام (lib/) | [05_FOLDER_STRUCTURE.md](./05_FOLDER_STRUCTURE.md) |
| قواعد تسمية المجلدات | [05_FOLDER_STRUCTURE.md](./05_FOLDER_STRUCTURE.md) |
| قواعد تسمية الملفات | [05_FOLDER_STRUCTURE.md](./05_FOLDER_STRUCTURE.md)، [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) |

---

### إذا أردت تعديل Naming Convention ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| الكلاسات، الدوال، المتغيرات | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) |
| الملفات والمجلدات | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) |
| مزودات Riverpod | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) |
| الاستثناءات والفشل | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) |
| الأدوات (Widgets) | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) |

---

### إذا أردت تعديل Clean Architecture ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| مبادئ العمارة النظيقة | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |
| الطبقات (Presentation، Domain، Data، Infrastructure) | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |
| التنظيم Feature-First | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |

---

### إذا أردت تعديل Enterprise Architecture ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| منصات التطبيقات الأربعة | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| محرك التوصيل | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md)، [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| الذكاء الاصطناعي | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md)، [21_AI_ROADMAP.md](./21_AI_ROADMAP.md) |
| الأمان المؤسسي | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md)، [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| المراقبة والمراقبة | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| النشر والتوسع | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md)، [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |

---

### إذا أردت تعديل Saudi Compliance ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| ZATCA (الفاتورة الإلكترونية) | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| منصة وصل | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| منصة بلدي | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| النفاذ الوطني (Nafath) | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| العنوان الوطني | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| بوابات الدفع (STC Pay، Mada) | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| Google Maps / Apple Maps | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| SMS / WhatsApp | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |

---

### إذا أردت تعديل Development Roadmap ← اذهب إلى ...

| ما تريد تعديله | الوثيقة المناسبة |
|---------------|-------------------|
| المراحل (0-5) | [20_DEVELOPMENT_ROADMAP.md](./20_DEVELOPMENT_ROADMAP.md) |
| المهام المكتملة | [20_DEVELOPMENT_ROADMAP.md](./20_DEVELOPMENT_ROADMAP.md) |
| المهام قيد الانتظار | [20_DEVELOPMENT_ROADMAP.md](./20_DEVELOPMENT_ROADMAP.md) |
| خطة الذكاء الاصطناعي | [21_AI_ROADMAP.md](./21_AI_ROADMAP.md) |

---

## انظر أيضًا

- [24_INDEX.md](./24_INDEX.md) — فهرس المشروع
- [28_DEPENDENCY_MAP.md](./28_DEPENDENCY_MAP.md) — خريطة الاعتماديات
- [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — المرجع الرسمي للمشروع

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
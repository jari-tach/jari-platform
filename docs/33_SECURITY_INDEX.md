# SAEQ — Security Index

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Review Date:** 2026-07-23  
> **Next Review:** 2027-01-23  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## فهرس الأمان

يجمع هذا الملف جميع سياسات الأمان الموجودة في مشروع SAEQ ويشير إلى الوثائق الأصلية.

---

### 1. سياسات الأمان الرئيسية

| السياسة | الوثيقة المرجعية | الحالة |
|--------|-------------------|--------|
| **التخزين الآمن** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 2 | ✅ مكتمل |
| **أمان الشبكة** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 3 | ✅ مكتمل |
| **المصادقة** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 4 | ✅ مكتمل |
| **التفويض** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 5 | ✅ مكتمل |
| **التحقق من المدخلات** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 6 | ✅ مكتمل |
| **حماية البيانات** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 7 | ✅ مكتمل |
| **تعزيز التطبيق** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 8 | ✅ مكتمل |
| **الخصوصية** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 9 | ✅ مكتمل |
| **أفضل الممارسات** | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — القسم 10 | ✅ مكتمل |

---

### 2. الوثائق ذات الصلة بالأمان

| الوثيقة | الوصف | الرابط |
|---------|-------|--------|
| [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | دليل الأمان الكامل — التخزين، الشبكة، المصادقة، التفويض، التحقق، التشفير، الخصوصية | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) | أمان واجهات برمجة التطبيقات — HTTPS، Certificate Pinning، Interceptors | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) | إدارة الأخطاء — لا يتم الكشف عن معلومات حساسة في رسائل الخطأ | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) | الامتثال السعودي — ZATCA، Nafath، بوابات الدفع | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) — القسم 29 | المعايير الأمنية المؤسسية — OWASP، ISO 27001، SOC 2، GDPR، SDAIA | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) — القسم 6 | ما لا يتم تسجيله — كلمات المرور، الرموز، PII، بيانات الدفع | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) | الأمان في النشر — الأسرار، المتغيرات البيئية | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |

---

### 3. القرارات الأمنية المعمارية

| رقم القرار | العنوان | الوثيقة المرجعية | الحالة |
|------------|---------|-------------------|--------|
| ARCH-007 | اعتماد flutter_secure_storage للبيانات الحساسة | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | ✅ معتمد |
| ARCH-013 | اعتماد HTTPS فقط مع certificate pinning | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | ✅ معتمد |
| ARCH-014 | اعتماد JWT للمصادقة | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | ✅ معتمد |

---

### 4. المكوّنات الأمنية

| المكوّن | الوظيفة | الوثيقة المرجعية |
|---------|----------|-------------------|
| flutter_secure_storage | التخزين الآمن للرموز والبيانات الحساسة | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| Dio + AuthInterceptor | إضافة JWT إلى رؤوس الطلبات | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| Dio + ErrorInterceptor | التقاط وتحويل أخطاء الأمان | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| LoggerService | تسجيل الأخطاء الأمنية بدون بيانات حساسة | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| Network Security Config | فرض HTTPS على Android | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |

---

### 5. المتطلبات الأمنية المعلقة

| المتطلب | الوثيقة المرجعية | الحالة |
|---------|-------------------|--------|
| Certificate Pinning | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | قيد التنفيذ |
| تشفير قاعدة البيانات | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | قيد التخطيط |
| كشف التلاعب (Root/Jailbreak) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | قيد التخطيط |
| ProGuard/R8 | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | قيد التخطيط |
| تدقيق أمني دوري | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | غير مبدوء |

---

## انظر أيضًا

- [32_KNOWN_LIMITATIONS.md](./32_KNOWN_LIMITATIONS.md) — القيود المعروفة
- [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — المرجع الرسمي للمشروع
- [24_INDEX.md](./24_INDEX.md) — فهرس المشروع

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
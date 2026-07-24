# SAEQ — Error Handling

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## 1. نظرة عامة

تطبق إدارة الأخطاء في مشروع SAEQ نهج **طبقاتي مكتوف**. تُلتقط الأخطاء عند حدود كل طبقة، وتُحوّل إلى استثناءات أو فشل مكتوفة، وتُنقل للأعلى. تتحمل طبقة العرض مسؤولية عرض رسائل مناسبة للمستخدم.

---

## 2. التسلسل الهرمي للأخطاء

```
Exception (Dart core)
├── AppException (استثناء التطبيق الأساسي)
│   ├── NetworkException
│   │   ├── TimeoutException
│   │   ├── NoInternetException
│   │   └── SocketException
│   ├── AuthException
│   │   ├── UnauthorizedException
│   │   ├── TokenExpiredException
│   │   └── InvalidCredentialsException
│   ├── ServerException
│   │   ├── BadRequestException
│   │   ├── NotFoundException
│   │   ├── ConflictException
│   │   ├── ForbiddenException
│   │   └── InternalServerErrorException
│   ├── ValidationException
│   ├── CacheException
│   └── UnknownException
└── Failure (طبقة المجال)
    ├── NetworkFailure
    ├── AuthFailure
    ├── ServerFailure
    ├── ValidationFailure
    ├── CacheFailure
    └── UnknownFailure
```

---

## 3. تدفق الاستثناءات

```
Presentation ← يعرض رسالة مناسبة للمستخدم
    ↑ catch (Failure)
Domain ← تحويل الاستثناءات إلى Failure
    ↑ catch (AppException)
Data ← تحويل الأخطاء الخام إلى AppException
    ↑ catch (DioException، إلخ)
Infrastructure ← عميل HTTP، قاعدة بيانات، إلخ
```

---

## 4. قواعد التنفيذ

- **طبقة البيانات:** التقاط جميع الاستثناءات الخام (`DioException`، `SocketException`، `SQLException`، إلخ) وتحويلها إلى استثناءات `AppException`.
- **طبقة المجال:** تلتقط حالات الاستخدام `AppException` وتحوّلها إلى `Failure`.
- **طبقة العرض:** تلتقط `Failure` وتحدّث الحالة برسائل مناسبة للمستخدم.
- **عدم نقل الاستثناءات الخام** إلى ما بعد طبقة البيانات.
- **تسجيل جميع الأخطاء** بسياق قبل تحويلها.

---

## 5. رسائل الخطأ

| نوع الاستثناء | الرسالة (عربي) | الرسالة (إنجليزي) |
|---------------|----------------|-------------------|
| `NoInternetException` | "تحقق من اتصالك بالإنترنت" | "Check your internet connection" |
| `TimeoutException` | "انتهت مدة الاتصال. حاول مرة أخرى" | "Connection timed out. Try again" |
| `UnauthorizedException` | "جلسة المستخدم انتهت. يرجى تسجيل الدخول" | "Session expired. Please log in" |
| `ServerException` | "حدث خطأ في الخادم. حاول مرة أخرى" | "Server error occurred. Try again" |
| `ValidationException` | "بيانات غير صالحة" | "Invalid data provided" |
| `UnknownException` | "حدث خطأ غير متوقع" | "An unexpected error occurred" |

---

## 6. عرض الأخطاء

- **الأخطاء المؤقتة:** عرض عبر `SnackBar` مع زر لإعادة المحاولة.
- **الأخطاء المحظورة:** عرض عبر `AlertDialog` مع تعليمات واضحة.
- **أخطاء التحقق من النموذج:** عرض بجانب حقل الإدخال ذو الصلة.
- **أخطاء الشبكة:** إظهار شريط شبكة في الأعلى للشاشة.

---

## 7. استراتيجيات التعافي

| نوع الخطأ | استراتيجية التعافي |
|------------|-------------------|
| الشبكة | إعادة المحاولة مع backoff أسي (حد أقصرى 3 محاولات) |
| المصادقة | إعادة توجيه إلى شاشة تسجيل الدخول |
| الخادم (5xx) | إعادة المحاولة مع backoff أسي |
| الخادم (4xx) | عرض رسالة مناسبة للمستخدم، بدون إعادة المحاولة |
| التحقق | تسليط الضوء على الحقول غير الصالحة، عرض الرسالة |
| التخزين المؤقت | الرجوع إلى البيانات المخزنة، إظهار مؤشر stale |

---

## 8. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| الأمان | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| التسجيل | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) |
| معايير البرمجة | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*

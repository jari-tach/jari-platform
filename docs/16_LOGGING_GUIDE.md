# SAEQ — Logging Guide

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## 1. نظرة عامة

يستخدم مشروع SAEQ حزمة `logger` للتسجيل المنظم والمرتب. تُستخدم السجلات للتصحيح، المراقبة، والتوثيق. لا يتم تسجيل البيانات الحساسة أبدًا.

---

## 2. مستويات التسجيل

| المستوى | متى يتم الاستخدام | الإخراج |
|--------|-------------|--------|
| `debug` | معلومات تشخيصية تفصيلية للتطوير | وحدة التحكم فقط (إصدارات تطوير) |
| `info` | رسائل تشغيلية عامة (إجراءات المستخدم، تغييرات الحالة) | وحدة التحكم + عن بُعد (الإنتاج) |
| `warning` | مشكلات قابلة للاسترداد لا تمنع التشغيل | وحدة التحكم + عن بُعد |
| `error` | أخطاء تؤثر على عملية واحدة ولكن ليست التطبيق | وحدة التحكم + عن بُعد + إبلاغ الأخطاء |
| `fatal` | أخطاء تتسبب في توقف التطبيق | وحدة التحكم + عن بُعد + إبلاغ الأخطاء |

---

## 3. إعداد Logger

```dart
class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 120,
      colors: kDebugMode,
      printEmojis: true,
      printTime: true,
    ),
    level: kDebugMode ? Level.debug : Level.info,
  );

  static void debug(String message, {Map<String, dynamic>? context}) {
    _logger.d(message, context: context);
  }

  static void info(String message, {Map<String, dynamic>? context}) {
    _logger.i(message, context: context);
  }

  static void warning(String message, {Map<String, dynamic>? context}) {
    _logger.w(message, context: context);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _logger.e(message, error: error, stackTrace: stackTrace, context: context);
  }

  static void fatal(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _logger.f(message, error: error, stackTrace: stackTrace, context: context);
  }
}
```

---

## 4. السياق

جميع إدخالات السجل يجب أن تتضمن بيانات سياق:

```dart
LoggerService.info(
  'Order accepted',
  context: {
    'orderId': orderId,
    'driverId': driverId,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

---

## 5. ماذا تسجل

| الحدث | المستوى | السياق |
|-------|--------|--------|
| بدء التطبيق | info | version، buildNumber، platform |
| تسجيل دخول المستخدم | info | userId، authMethod |
| تسجيل خروج المستخدم | info | userId، sessionDuration |
| إرسال طلب API | debug | endpoint، method، requestBody |
| استقبال استجابة API | debug | endpoint، statusCode، responseBody |
| خطأ API | error | endpoint، statusCode، errorMessage |
| إنشاء طلب | info | orderId، customerId |
| قبول طلب | info | orderId، driverId |
| تغيير حالة الطلب | info | orderId، oldStatus، newStatus |
| فقدان الاتصال | warning | connectivityType |
| فشل التخزين المؤقت | debug | cacheKey |
| نجاح التخزين المؤقت | debug | cacheKey |
| فشل التحقق | warning | field، value، rule |
| استثناء غير مُعالج | fatal | exception، stackTrace، context |

---

## 6. ماذا لا تسجله

- **كلمات المرور** — لا تسجيل أبدًا.
- **الرموز** — لا تسجيل الرموز، الرموز المميزة، أو JWT.
- **PII** — لا تسجيل معلومات التعريف الشخصية (الاسم، الهاتف، البريد الإلكتروني، العنوان).
- **بيانات الدفع** — لا تسجيل أرقام البطاقات الائتمان، الحسابات البنكية، أو تفاصيل المعاملات.
- **النص الكامل للطلب/الاستجابة** — سجل الحقول غير الحساسة فقط أو استخدم الحذف.

---

## 7. التسجيل عن بُعد

- في الإنتاج، إرسال السجلات إلى خدمة تسجيل عن بُعد (مثال: Sentry، Firebase Crashlytics).
- استخدام صف انتظار في الخلفية لتجنب حظر الواجهة.
- تنفيذ تدوير السجلات لمنع استخدام القرص المفرط.
- احترام خصوصية المستخدم — السماح للمستخدمين بإلغاء الاشتراك من التسجيل.

---

## 8. مدة الاحتفاظ بالسجلات

| البيئة | مدة الاحتفاظ | التخزين |
|--------|-------------|--------|
| التطوير | حتى إعادة تشغيل التطبيق | وحدة التحكم |
| الاختبار | 7 أيام | خدمة عن بُعد |
| الإنتاج | 30 يومًا | خدمة عن بُعد |

---

## 9. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| الأمان | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| إدارة الأخطاء | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| العمل بدون إنترنت | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*

# PROJECT STABILIZATION — الخطوة 2E: استرجاع تصريف طبقة الشبكة والأمان فقط (Network Security Compilation Recovery Only)

> **الاعتماد على:** [docs/STABILIZATION_STEP_01_DIAGNOSIS.md](./STABILIZATION_STEP_01_DIAGNOSIS.md)، [docs/STABILIZATION_STEP_02A_DRIFT_RECOVERY.md](./STABILIZATION_STEP_02A_DRIFT_RECOVERY.md)، [docs/STABILIZATION_STEP_02B_LOGGER_RECOVERY.md](./STABILIZATION_STEP_02B_LOGGER_RECOVERY.md)، [docs/STABILIZATION_STEP_02C_SECURE_STORAGE_RECOVERY.md](./STABILIZATION_STEP_02C_SECURE_STORAGE_RECOVERY.md)، [docs/STABILIZATION_STEP_02D_OFFLINE_RECOVERY.md](./STABILIZATION_STEP_02D_OFFLINE_RECOVERY.md)
> **النطاق:** `ApiClient`، `Certificate Pinning`، والاعتماد المباشر والاستيرادات المباشرة بينهما فقط.
> **لم يُلمَس:** `Riverpod`، `AppException`، Warnings، Info، ولا أي مجموعة أخرى.
> **التاريخ:** 2026-07-24

---

## 1- أخطاء ApiClient قبل الإصلاح

**2 خطأ**، وكلاهما في `lib/core/security/security_interceptors.dart` (داخل صنف `TokenRefreshManager`):

| السطر | الخطأ |
|---|---|
| 202 | `Undefined class 'ApiClient'` (في تعريف الحقل `final ApiClient _apiClient;`) |
| 207 | `Undefined class 'ApiClient'` (في توقيع الـ Constructor `required ApiClient apiClient`) |

لا توجد أي أخطاء أخرى متعلقة بـ `ApiClient` في `api_client.dart` نفسه، أو في `api_interceptors.dart`، أو في `app_service_registry.dart`، أو في `service_locator.dart` — هذه الملفات الأربعة كانت خالية تماماً من أي خطأ متعلق بـ `ApiClient` قبل هذه الخطوة.

---

## 2- أخطاء Certificate Pinning قبل الإصلاح

**2 خطأ**، وكلاهما في `lib/core/security/security_interceptors.dart` (داخل صنف `CertificatePinning`):

| السطر | الخطأ |
|---|---|
| 119 | `undefined_getter`: الخاصية `pin` غير معرَّفة على النوع `X509Certificate` |
| 131 | `undefined_method`: الدالة `_calculateSha256` غير معرَّفة على النوع `CertificatePinning` |

---

## 3- السبب الجذري لكل خطأ

**ApiClient (الخطآن 202، 207):**
`security_interceptors.dart` يستخدم النوع `ApiClient` داخل `TokenRefreshManager` (حقل + معامل Constructor) **دون استيراد الملف الذي يعرّفه** (`lib/core/services/api/api_client.dart`). سبب بسيط ومباشر: استيراد مفقود، لا علاقة له بأي تصميم أو توقيع دالة.

**Certificate Pinning (الخطآن 119، 131):**
1. **`certificate.pin` (سطر 119):** صنف `X509Certificate` في مكتبة `dart:io` القياسية **لا يحتوي أصلاً على خاصية اسمها `pin`** — هذه الخاصية غير موجودة في أي إصدار من Dart SDK. الخصائص الفعلية المتاحة على هذا الصنف هي: `subject`, `issuer`, `startValidity`, `endValidity`, `der` (البيانات الخام Bytes بصيغة DER)، `pem`. الكود الأصلي كان يفترض وجود خاصية جاهزة لحساب "البصمة" (Pin) مباشرة من الشهادة، وهذا افتراض خاطئ عن الـ API.
2. **`_calculateSha256` (سطر 131):** كانت هناك خاصية أخرى منفصلة تماماً (`String get pin => 'sha256/${_calculateSha256(_certificateBytes)}';`) تستدعي دالة `_calculateSha256` **لم تُعرَّف إطلاقاً في الصنف** — كانت مجرد استدعاء بلا تنفيذ (Skeleton). كما أن هذه الخاصية كانت تعتمد على حقل `_certificateBytes` الذي كان **دائماً قائمة فارغة `[]`** (لا يوجد أي كود في المشروع يُسنِد له قيمة فعلية)، أي أن هذا المسار الكامل كان "هيكلاً معطَّلاً بالتصميم" وليس مجرد نقص تنفيذ عابر — لم يكن بالإمكان مطلقاً أن يُحسَب Pin صحيح من حقل فارغ دائماً.

كلا الخطأين في Certificate Pinning جذرهما واحد: **الكود كان يحاول حساب "بصمة" الشهادة من مصدر بيانات غير صحيح (خاصية غير موجودة + حقل فارغ دائماً) بدل استخدام البيانات الفعلية للشهادة الممرَّرة كمعامل للدالة (`certificate.der`)**.

---

## 4- الملفات التي تم تعديلها

| # | الملف | نوع التعديل |
|---|---|---|
| 1 | `lib/core/security/security_interceptors.dart` | (أ) إضافة `import '../services/api/api_client.dart';` لحل خطأي `ApiClient`. (ب) تصحيح `CertificatePinning.validateCertificate` لحساب البصمة من `certificate.der` الفعلية بدل الخاصية غير الموجودة `certificate.pin`. (ج) تعريف `_calculateSha256` فعلياً (SHA-256 + Base64) بدل الاستدعاء بلا تنفيذ. (د) حذف الخاصية `pin` والحقل `_certificateBytes` القديمين، لأنهما كانا معطَّلين بالتصميم (حقل فارغ دائماً لا يُسنَد له أي قيمة في أي مكان من المشروع) واستُبدِلا بدالة داخلية صحيحة (`_calculatePin`) تستقبل الشهادة الفعلية كمعامل |

**لم يُعدَّل أي ملف آخر.** لم يُلمَس `api_client.dart`، ولا `api_interceptors.dart`، ولا `app_service_registry.dart`، ولا `service_locator.dart` — لم تكن بها أي أخطاء من هذه المجموعة، ولا احتاج الإصلاح لمسها.

---

## 5- التوقيعات قبل وبعد الإصلاح

**قبل:**
```dart
// لا يوجد استيراد لـ ApiClient في هذا الملف

bool validateCertificate(X509Certificate certificate) {
  final pin = certificate.pin;              // ← خاصية غير موجودة
  final isValid = _allowedCertificates.contains(pin);
  ...
}

String get pin => 'sha256/${_calculateSha256(_certificateBytes)}'; // ← _calculateSha256 غير معرَّفة، _certificateBytes فارغة دائماً
List<int> _certificateBytes = [];
```

**بعد:**
```dart
import '../services/api/api_client.dart';   // ← تمت إضافته

bool validateCertificate(X509Certificate certificate) {
  final pin = _calculatePin(certificate);   // ← يحسب من الشهادة الفعلية
  final isValid = _allowedCertificates.contains(pin);
  ...
}

String _calculatePin(X509Certificate certificate) {
  return 'sha256/${_calculateSha256(certificate.der)}'; // ← يستخدم DER الحقيقي للشهادة
}

String _calculateSha256(List<int> bytes) {
  return base64.encode(sha256.convert(bytes).bytes);    // ← تنفيذ حقيقي وصحيح
}
```

`TokenRefreshManager` (توقيعه العلني لم يتغيّر إطلاقاً؛ فقط أصبح `ApiClient` قابلاً للحل بعد إضافة الاستيراد):
```dart
class TokenRefreshManager {
  final ApiClient _apiClient; // ← بدون تغيير، فقط أصبح النوع محلولاً الآن
  TokenRefreshManager({..., required ApiClient apiClient}); // ← بدون تغيير
}
```

---

## 6- إصدار Dio والمكتبات المرتبطة المستخدَم فعلياً

تم فحص `pubspec.yaml` والإصدارات المُحلَّة فعلياً (`flutter pub deps`) قبل أي تعديل:

| الحزمة | الإصدار المُحدَّد في pubspec.yaml | الإصدار المُحلَّل فعلياً |
|---|---|---|
| `dio` | `^5.10.0` | **5.10.0** |
| `crypto` | `^3.0.3` | **3.0.7** |

كلا الإصدارين حديثان (Dio 5.x، لا Dio 4.x القديم)، و `X509Certificate.der` و `crypto.sha256`/`Hmac` هي APIs مستقرة ومستخدَمة فعلياً في نفس الملف مسبقاً (`Hmac(sha256, key)` في `_signRequest`)، وليست تخميناً من إصدارات أقدم. **لم يتم تعديل أي API قبل التأكد من توافقه مع الإصدارات المثبَّتة فعلياً.**

---

## 7- عدد أخطاء المجموعة قبل الإصلاح

**4 أخطاء** (2 ApiClient + 2 Certificate Pinning) — تفصيلها في القسمين 1 و2 أعلاه.

---

## 8- عدد أخطاء المجموعة بعد الإصلاح

**0 خطأ.** لا يظهر أي خطأ منسوب إلى `ApiClient` أو `CertificatePinning` في نتيجة `flutter analyze` النهائية.

---

## 9- إجمالي Errors المتبقية في المشروع

**1 خطأ فقط** (بعد أن كانت 5 أخطاء في نهاية STEP 2D). **انخفاض بمقدار 4 أخطاء (80%↓)** ضمن هذه الخطوة، وجميعها من مجموعة Network Security حصراً.

الخطأ الوحيد المتبقي في المشروع بالكامل:

| الملف | الخطأ | المجموعة |
|---|---|---|
| `app_error_handler.dart:169` | `non_exhaustive_switch_expression` (ينقصه `SerializationException`) | Riverpod/AppException — **محظورة صراحة في هذه الخطوة، لم تُلمَس** |

---

## 10- إجمالي Warnings المتبقية

**7 تحذيرات — بدون أي تغيير** عن نهاية STEP 2D. لم تُصلَح أي تحذيرات (خارج نطاق هذه الخطوة صراحة). أحد التحذيرات المذكورة (`_apiClient` غير مستخدَم في `TokenRefreshManager`) كان موجوداً بالفعل **إلى جانب** خطأ `ApiClient` غير المعرَّف على نفس السطر (بعمودين مختلفين)؛ بعد حل الخطأ بقي التحذير كما هو دون تغيير.

---

## 11- إجمالي Info المتبقية

**28 ملاحظة** (بعد أن كانت 29 في نهاية STEP 2D). **انخفاض بمقدار ملاحظة واحدة فقط**، وهي `prefer_final_fields` الخاصة بالحقل `_certificateBytes` الذي تم حذفه لأنه كان معطَّلاً بالتصميم (انظر القسم 3 والقسم 4) — لم يُطلَب حذفه لتحسين الأسلوب، بل اختفت ملاحظته تلقائياً كنتيجة مباشرة لحذف الكود الميت المرتبط به.

---

## 12- هل بقي Certificate Pinning مفعَّلاً؟

**Certificate Pinning موجود في الكود ويعمل منطقياً بشكل صحيح (Fail-Closed)، لكنه غير مفعَّل فعلياً على مستوى التطبيق** — وهذا لم يتغيّر بهذه الخطوة:

- علم `AppConfig.enableCertificatePinning` في `lib/core/config/app_config.dart:81` كان ولا يزال `false` (معطَّل، مع تعليق `// TODO: Enable in production` موجود مسبقاً في الكود، لم تتم إضافته الآن ولم يُلمَس).
- صنف `CertificatePinning` نفسه **لم يكن ولا يزال غير مربوط بـ Dio/`ApiClient`** (لا يوجد أي `badCertificateCallback` أو `IOHttpClientAdapter` يستخدمه في أي مكان من المشروع — تم التحقق بالبحث الشامل). هذا لم يتغيّر: لم يُربَط الصنف بطبقة الشبكة في هذه الخطوة، لأن ربطه يُعتبر "دمج جديد في معمارية الشبكة" وهو محظور صراحة في التعليمات ("لا تضف Network architecture جديدة"، "لا تنشئ Client جديداً موازياً").
- **ما تم إصلاحه هو فقط قابلية تصريف منطق التحقق نفسه** (`validateCertificate`)، بحيث يصبح **جاهزاً للاستخدام الصحيح لاحقاً** إذا وعندما يُقرَّر ربطه، دون أي تغيير في مستوى الحماية أو المنطق الأمني.

---

## 13- هل تم قبول أي شهادة بشكل مفتوح؟

**لا، إطلاقاً.** لم تتم إضافة أي `badCertificateCallback = (_, __, ___) => true` أو ما يعادله. على العكس، الإصلاح **حافظ على مبدأ Fail-Closed** بدقة: قائمة `_allowedCertificates` بقيت **فارغة تماماً** كما كانت (لا توجد أي بصمة شهادة حقيقية أو مُخترَعة فيها)، وبالتالي `_allowedCertificates.contains(pin)` سيُعيد **`false` دائماً** لأي شهادة فعلية تُفحَص — أي أن أي استخدام مستقبلي لهذه الدالة سيرفض كل الشهادات حتى تُضاف بصمات حقيقية فعلية من بيئة الإنتاج. هذا يطبّق حرفياً القاعدة: *"إذا تعذر تنفيذ التحقق بسبب عدم وجود شهادة أو بصمة فعلية: لا تخترع قيمة، حافظ على fail-closed"*.

---

## 14- هل تم تغيير baseUrl أو timeouts أو headers؟

**لا.** لم يُعدَّل `api_client.dart` إطلاقاً (لم يكن به أي خطأ). قيم `AppConfig.baseApiUrl`، و `connectTimeout`/`receiveTimeout`/`sendTimeout` (15 ثانية لكل منها)، وHeaders الافتراضية (`Content-Type`, `Accept`, `Accept-Language`) بقيت كما هي حرفياً بدون أي تغيير.

---

## 15- نتيجة flutter analyze المختصرة

```
Analyzing saeq_driver...
36 issues found.
```

| النوع | قبل STEP 2E | بعد STEP 2E |
|---|---|---|
| Errors | 5 | **1** |
| Warnings | 7 | **7** |
| Info | 29 | **28** |
| **الإجمالي** | **41** | **36** |

الخطأ الوحيد المتبقي (`app_error_handler.dart:169`) **لا علاقة له بـ ApiClient أو Certificate Pinning إطلاقاً**، وينتمي حصراً لمجموعة `Riverpod`/`AppException` المحظورة صراحة في هذه الخطوة. **لم يُلمَس.**

---

## 16- أي مخاطر أمنية متبقية

1. **Certificate Pinning غير مفعَّل فعلياً في مسار الشبكة الحقيقي** (كما هو موضَّح في القسم 12) — هذا **خطر أمني قائم مسبقاً وموثَّق أصلاً** في الكود نفسه (`enableCertificatePinning = false` + تعليق TODO)، وليس خطراً جديداً نتج عن هذه الخطوة. ربطه الفعلي بطبقة الشبكة يتطلب قراراً هندسياً في خطوة لاحقة (خارج نطاق "إصلاح تصريف فقط").
2. **لا توجد أي بصمات شهادات حقيقية في `_allowedCertificates`** — هذا يعني أن التحقق سيرفض كل الشهادات إن استُخدِم الآن (Fail-Closed آمن)، وهذا **مقصود ومطلوب صراحة** بموجب التعليمات (عدم اختراع قيم)، لكنه يعني أن الميزة تحتاج بيانات إنتاج حقيقية (بصمات SHA-256 الفعلية لشهادات الخادم) قبل أي تفعيل مستقبلي — هذا الأمر **موجود ومُوثَّق مسبقاً في تعليق `TODO` قديم لم يُلمَس**.
3. **لا يوجد أي تسريب أمني جديد** ناتج عن هذه الخطوة: لم تُخفَّض أي حماية موجودة، لم يُحذَف أي Interceptor، ولم يُستخدَم `dynamic` لإخفاء أي خطأ نوع.
4. **`TokenRefreshManager.refreshAccessToken()` يبقى بدون تنفيذ فعلي** (منطقه معلَّق بالكامل بتعليقات `// TODO` موجودة مسبقاً)، لذلك لا يوجد حالياً تجديد فعلي لتوكن الدخول عند انتهاء صلاحيته — هذا سلوك موجود مسبقاً ولم يتغيّر (لم تُضَف "Authentication flow جديدة" كما تنص التعليمات بالمنع).

---

*تم إنجاز STEP 2E ضمن الحدود المطلوبة تماماً: لم يُصلَح خطأ Riverpod/AppException المتبقي، لم تُصلَح أي Warnings أو Info، لم تُضَف نقاط API جديدة، ولم يُغيَّر أي Interceptor أو baseUrl أو timeouts أو headers، ولم يُقبَل أي شهادة بشكل مفتوح، ولم تُخترَع أي بصمة شهادة. لم يُشغَّل `flutter test`، ولم يُشغَّل التطبيق على أي جهاز أو محاكي. المشروع الآن به خطأ واحد فقط متبقٍ (خارج نطاق أي خطوة Stabilization حتى الآن)، وتتوقف هذه الخطوة هنا بانتظار التعليمات التالية.*

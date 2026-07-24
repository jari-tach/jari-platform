# SAEQ — API Architecture

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## 1. نظرة عامة

يستخدم مشروع SAEQ **Dio** كعميل HTTP مع نهج طبقاتي: interceptors للهتمامات العرضية، عملاء نوعيين لنقاط النهاية، وتسلسل تلقائي للتسلسل/إلغاء التسلسل.

---

## 2. الهيكل

```
Domain Layer
  └─ UseCase → UseCase
Data Layer
  └─ Repository Impl → Repository Impl
    └─ ApiService (Retrofit) → LocalDB (Drift)
Infrastructure Layer
  └─ Dio Client → Interceptors
```

---

## 3. إعداد Dio

```dart
class ApiClient {
  static const String _baseUrl = 'https://api.saeq.example';
  static const int _connectTimeout = 30000;
  static const int _receiveTimeout = 30000;
  static const int _sendTimeout = 30000;

  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(milliseconds: _connectTimeout),
      receiveTimeout: const Duration(milliseconds: _receiveTimeout),
      sendTimeout: const Duration(milliseconds: _sendTimeout),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: {
        'Accept-Language': 'ar',
        'X-App-Version': AppConstants.appVersion,
        'X-Platform': Platform.operatingSystem,
      },
    ));

    dio.interceptors.addAll([
      AuthInterceptor(dio),
      LoggingInterceptor(dio),
      RetryInterceptor(dio),
      ErrorInterceptor(dio),
    ]);

    return dio;
  }
}
```

---

## 4. الـ Interceptors

### 4.1 Auth Interceptor
- إضافة JWT token إلى رأس `Authorization`.
- تجديد الرموز منتهية الصلاحية تلقائيًا.
- إعادة توجيه إلى تسجيل الدخول عند فشل المصادقة المستمر.

### 4.2 Logging Interceptor
- تسجيل طريقة الطلب، URL، الرؤوس، والنص (إصدارات تطوير فقط).
- تسجيل حالة الاستجابة، الرؤوس، والنص (إصدارات تطوير فقط).
- عدم تسجيل البيانات الحساسة (الرموز، كلمات المرور، PII).

### 4.3 Retry Interceptor
- إعادة محاولة الطلبات الفاشلة مع backoff أسي.
- الحد الأقصى 3 محاولات.
- فقط إعادة المحاولة على أخطاء الشبكة واستجابات 5xx.
- احترام رأس `Retry-After`.

### 4.4 Error Interceptor
- التقاط جميع مثيلات `DioException`.
- تحويلها إلى استثناءات `AppException`.
- تسجيل الأخطاء بسياق.
- معالجة أخطاء الاتصال بشكل مناسب.

---

## 5. عميل API (Retrofit)

```dart
@RestApi(baseUrl: 'https://api.saeq.example')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @GET('/health')
  Future<HealthResponse> getHealthStatus();

  @POST('/auth/login')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @GET('/orders')
  Future<List<OrderModel>> getOrders({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('status') String? status,
  });

  @GET('/orders/{id}')
  Future<OrderModel> getOrderById(@Path('id') String orderId);

  @POST('/orders/{id}/accept')
  Future<OrderModel> acceptOrder(@Path('id') String orderId);
}
```

---

## 6. التسلسل

- استخدام `json_serializable` للتسلسل/إلغاء التسلسل.
- استخدام `freezed` للفئات غير القابلة للتغيير مع أنواع اتحادية (عند الموافقة).
- جميع نماذج API يجب أن تنفذ `fromJson` و `toJson`.
- استخدام `@JsonKey` لربط أسماء الحقول والقيم الافتراضية.

---

## 7. إصدار واجهة برمجة التطبيقات

- استخدام إصدار URL في المسار: `/api/v1/orders`، `/api/v2/orders`.
- الحفاظ على التوافق العكسي لمدة نسختين على الأقل.
- إيقاف الإصدارات القديمة بإشعار مسبق 6 أشهر.
- توثيق جميع التغييرات في سجل التغييرات.

---

## 8. حدود المعدل

- تنفيذ حدود معدل على جانب العميل لمنع إساءة الاستخدام.
- استخدام خوارزمية bucket token أو sliding window.
- عرض رسائل مناسبة للمستخدم عند تطبيق الحدود.
- وضع الطلبات في الصف عند تطبيق الحدود وإعادة المحاولة عند السماح.

---

## 9. أفضل الممارسات

- استخدام HTTPS فقط (فرض عبر تكوين أمان الشبكة على Android).
- تنفيذ certificate pinning للإنتاج.
- استخدام API keys أو OAuth 2.0 للمصادقة.
- استخدام مهلات للطلبات والاستجابات.
- تنفيذ منطق إعادة المحاولة مع backoff أسي.
- تسجيل مكالمات API للتصحيح (بدون بيانات حساسة).
- استخدام عناوين URL خاصة بالبيئة.
- معالجة أخطاء API بشكل مناسب مع رسائل مناسبة للمستخدم.
- توثيق جميع نقاط API مع أمثلة.

---

## 10. نقاط API الرئيسية

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | تسجيل الدخول |
| POST | `/api/v1/auth/register` | تسجيل سائق جديد |
| POST | `/api/v1/auth/refresh` | تجديد الرمز |
| POST | `/api/v1/auth/logout` | إنهاء الجلسة |
| GET | `/api/v1/orders` | قائمة الطلبات |
| GET | `/api/v1/orders/{id}` | تفاصيل الطلب |
| POST | `/api/v1/orders/{id}/accept` | قبول الطلب |
| POST | `/api/v1/orders/{id}/reject` | رفض الطلب |
| POST | `/api/v1/deliveries/start` | بدء التسليم |
| POST | `/api/v1/deliveries/{id}/pickup` | تأكيد الاستلام |
| POST | `/api/v1/deliveries/{id}/deliver` | تأكيد التسليم |

---

## 11. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| الأمان | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| قاعدة البيانات | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| العمل بدون إنترنت | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*

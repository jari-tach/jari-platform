# SAEQ — Naming Convention

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)، [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md)  

---

## 1. القواعد العامة

| العنصر | القاعدة | المثال |
|--------|--------|--------|
| الكلاسات، الـ Enums، الـ Typedefs | PascalCase | `OrderService`، `DeliveryStatus`، `OrderCallback` |
| الدوال، الـ Methods، المتغيرات | camelCase | `getOrders()`، `isLoading`، `calculateTotal()` |
| الثوابت (static const) | lowerCamelCase | `defaultPadding`، `apiTimeoutSeconds` |
| الثوابت (compile-time const) | lowerCamelCase | `maxRetryAttempts`، `defaultPageSize` |
| الملفات | snake_case | `order_service.dart`، `driver_profile.dart` |
| المجلدات | snake_case | `features/orders/`، `core/utils/` |
| المعلمات | camelCase | `orderId`، `includeDetails` |
| معاملات الأنواع (generics) | PascalCase (حرف واحد أو وصفية) | `T`، `E`، `Key`، `Value` |

---

## 2. التسمية الخاصة بالميزات

| العنصر | القاعدة | المثال |
|--------|--------|--------|
| فئات الميزات | PascalCase + لاحقة `Feature` | `OrdersFeature`، `DriverFeature` |
| حالات الاستخدام | PascalCase + لاحقة `UseCase` | `GetOrdersUseCase`، `AcceptOrderUseCase` |
| الكيانات | PascalCase | `Order`، `Driver`، `Delivery` |
| واجهات المستودعات | PascalCase + لاحقة `Repository` | `OrderRepository`، `DriverRepository` |
| مصادر البيانات | PascalCase + لاحقة `DataSource` | `OrderRemoteDataSource`، `OrderLocalDataSource` |
| النماذج | PascalCase + لاحقة `Model` | `OrderModel`، `DriverModel` |
| نماذج العرض | PascalCase + لاحقة `ViewModel` | `OrdersViewModel`، `DriverProfileViewModel` |
| فئات الحالة | PascalCase + لاحقة `State` | `OrdersState`، `AuthState` |

---

## 3. تسمية المزودات (Riverpod)

| العنصر | القاعدة | المثال |
|--------|--------|--------|
| مزودات StateNotifier | camelCase + لاحقة `Provider` | `ordersProvider`، `authStateProvider` |
| مزودات القيم البسيطة | camelCase + لاحقة `Provider` | `appThemeModeProvider`، `appLocaleProvider` |
| مزودات Future | camelCase + لاحقة `Provider` | `driverProfileProvider`، `ordersListProvider` |
| مزودات Stream | camelCase + لاحقة `Provider` | `orderUpdatesProvider`، `locationStreamProvider` |
| مزودات Family | camelCase + لاحقة `Provider` | `orderByIdProvider`، `driverByIdProvider` |

---

## 4. تسمية الاستثناءات والفشل

| العنصر | القاعدة | المثال |
|--------|--------|--------|
| الاستثناءات | PascalCase + لاحقة `Exception` | `NetworkException`، `AuthException` |
| الفشل | PascalCase + لاحقة `Failure` | `NetworkFailure`، `ServerFailure` |
| رموز الأخطاء | SCREAMING_SNAKE_CASE | `ERROR_NETWORK_TIMEOUT`، `ERROR_AUTH_INVALID_TOKEN` |

---

## 5. الثوابت والمفاتيح

| العنصر | القاعدة | المثال |
|--------|--------|--------|
| الثوابت النصية | lowerCamelCase | `appNameKey`، `defaultLanguageCode` |
| الثوابت الرقمية | lowerCamelCase | `defaultPageSize`، `maxImageSizeBytes` |
| أسماء الطرق | kebab-case | `'orders-list'`، `'driver-profile'` |
| مسارات الطرق | kebab-case مع `/` بادئ | `'/orders'`، `'/driver/profile'` |
| مفاتيح SharedPreferences | SCREAMING_SNAKE_CASE | `KEY_USER_TOKEN`، `KEY_LAST_SYNC_TIME` |
| المفاتيح العامة | lowerCamelCase + لاحقة `Key` | `navigatorKey`، `scaffoldKey` |

---

## 6. تسمية الأدوات (Widgets)

| العنصر | القاعدة | المثال |
|--------|--------|--------|
| Stateless Widgets | PascalCase | `SaeqPrimaryButton`، `OrderListItem` |
| Stateful Widgets | PascalCase | `AnimatedCounter`، `LocationTracker` |
| Inherited Widgets | PascalCase | `ThemeProvider`، `AuthScope` |
| CustomPainter | PascalCase + لاحقة `Painter` | `WavePainter`، `GradientPainter` |

---

## 7. تسمية الملفات

| نوع الملف | القاعدة | المثال |
|-----------|--------|--------|
| ملفات Dart عامة | snake_case | `order_service.dart`، `auth_interceptor.dart` |
| ملفات الاختبار | snake_case + لاحقة `_test` | `order_service_test.dart` |
| تسجيل الميزة | snake_case + لاحقة `_feature` | `orders_feature.dart` |
| ملفات barrel | snake_case | `models.dart`، `entities.dart` |
| الثوابت | snake_case | `app_constants.dart` |

---

## 8. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| معايير البرمجة | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| هيكل المجلدات | [05_FOLDER_STRUCTURE.md](./05_FOLDER_STRUCTURE.md) |
| نظام التصميم | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |

---

*هذه الوثيقة جزء من المرجع الرسمي لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*

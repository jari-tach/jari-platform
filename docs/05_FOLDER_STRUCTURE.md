# SAEQ — Folder Structure

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)، [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md)  

---

## 1. التخطيط المفصل للمجلدات

### 1.1 الهيكل العام

```
lib/
├── main.dart
├── core/
│   ├── config/
│   │   ├── app_config.dart              # متغيرات البيئة ونقاط نهاية API
│   │   └── flavors/                     # نكهات البناء (dev، staging، prod)
│   ├── constants/
│   │   ├── app_constants.dart           # بيانات التطبيق، الأبعاد، المدد
│   │   └── app_keys.dart                # المفاتيح العامة للتنقل/الاختبار
│   ├── di/
│   │   ├── di.dart                    # إعداد محرك الخدمات (get_it)
│   │   └── di_module.dart             # تسجيل الوحدات
│   ├── error/
│   │   ├── exceptions/                  # الاستثناءات الخاصة بالمجال
│   │   ├── failures/                    # أنواع الفشل لنقل الأخطاء
│   │   └── app_error_handler.dart       # معالج الأخطاء المركزي
│   ├── localization/
│   │   ├── app_localizations.dart       # مفوض التدوين اللغوي
│   │   ├── app_localizations_en.arb     # ترجمات الإنجليزية
│   │   └── app_localizations_ar.arb     # ترجمات العربية
│   ├── logging/
│   │   └── logger_service.dart          # تسجيل منظم
│   ├── network/
│   │   ├── interceptors/              # interceptors Dio (auth، logging، retry)
│   │   ├── network_info.dart          # فحص الاتصال
│   │   └── api_client.dart            # عميل HTTP على أساس Dio
│   ├── platform/
│   │   ├── platform_info.dart         # اكتشاف المنصة
│   │   └── device_info.dart           # بيانات الجهاز
│   ├── providers/
│   │   ├── app_providers.dart         # المزودات العالمية (التوجيه، السمة، اللغة)
│   │   └── providers.dart             # إعادة التصدير
│   ├── routes/
│   │   ├── app_router.dart            # إعداد GoRouter
│   │   ├── route_names.dart           # ثوابت أسماء الطرق
│   │   └── route_paths.dart           # ثوابت مسارات الطرق
│   ├── services/
│   │   ├── api/
│   │   │   └── api_service.dart       # خدمة API عالية المستوى
│   │   ├── auth/
│   │   │   └── auth_service.dart      # خدمة المصادقة
│   │   └── storage/
│   │       └── storage_service.dart   # خدمة التخزين
│   ├── theme/
│   │   ├── app_theme.dart             # بيانات السمة
│   │   ├── app_colors.dart            # لوحة الألوان
│   │   ├── app_text_styles.dart       # الطباعة
│   │   ├── app_dimensions.dart        # المسافات، النصف الكرة، الأحجام
│   │   └── widgets/                   # أدوات مخصصة للسمة
│   └── utils/
│       ├── extensions/                # امتدادات Dart/Flutter
│       ├── validators/                # التحقق من المدخلات
│       ├── formatters/                # منسقات النص
│       └── helpers/                   # دوال مساعدة
├── shared/
│   ├── services/
│   │   └── app_service_registry.dart  # سجل الخدمات
│   ├── widgets/
│   │   ├── saeq_primary_button.dart
│   │   ├── saeq_section_card.dart
│   │   └── ...                        # أدوات مشتركة أخرى
│   └── utils/
│       └── ...                        # أدوات مشتركة
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── auth_feature.dart
│   ├── delivery/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── delivery_feature.dart
│   ├── driver/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── welcome_screen.dart
│   │   │   ├── widgets/
│   │   │   └── viewmodels/
│   │   └── driver_feature.dart
│   ├── orders/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── orders_feature.dart
│   └── profile/
│       ├── data/
│       ├── domain/
│       ├── presentation/
│       └── profile_feature.dart
└── main.dart
```

---

## 2. قواعد تسمية المجلدات

| المجلد | الغرض |
|--------|-------|
| `core/` | البنية الأساسية المشتركة عبر التطبيق بأكمله |
| `shared/` | مكوّنات قابلة لإعادة الاستخدام لا تناسب `core/` أو ميزة محددة |
| `features/` | وحدات ميزات مستقلة |
| `data/` | طبقة البيانات داخل الميزة (النماذج، مصادر البيانات، تطبيقات المستودعات) |
| `domain/` | طبقة المجال داخل الميزة (الكيانات، حالات الاستخدام، واجهات المستودعات) |
| `presentation/` | طبقة واجهة المستخدم داخل الميزة (الصفحات، الأدوات، وحدات التحكم في الحالة) |
| `pages/` | طرق عرض كاملة الشاشة |
| `widgets/` | مكوّنات فرعية قابلة لإعادة الاستخدام داخل الميزة |
| `viewmodels/` | وحدات تحكم في الحالة |

---

## 3. قواعد تسمية الملفات

| نوع الملف | القاعدة | المثال |
|-----------|--------|--------|
| ملفات Dart عامة | snake_case | `order_service.dart`، `auth_interceptor.dart` |
| ملفات الاختبار | snake_case + لاحقة `_test` | `order_service_test.dart` |
| تسجيل الميزة | snake_case + لاحقة `_feature` | `orders_feature.dart` |
| ملفات barrel | snake_case | `models.dart`، `entities.dart` |
| الثوابت | snake_case | `app_constants.dart` |

> تفاصيل قواعد التسمية الكاملة موجودة في [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md)

---

## 4. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| العمارة النظيقة | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |
| معايير البرمجة | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| قواعد التسمية | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) |
| نظام التصميم | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |

---

*هذه الوثيقة جزء من المرجع الرسمي لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*

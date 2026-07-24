# SAEQ — Diagram Index

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Review Date:** 2026-07-23  
> **Next Review:** 2027-01-23  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## فهرس الرسومات

توضح هذه الصفحة جميع الرسومات (Diagrams) والصور (Images) المستخدمة في مشروع SAEQ.

> **ملاحظة مهمة:** لا توجد رسومات أو صور داخل ملفات Markdown. جميع الرسومات تُخزن في `docs/diagrams/` والصور في `docs/images/`.

---

## 📊 الرسومات (docs/diagrams/)

### system/

| اسم الرسم | الوصف | الوثيقة المرجعية |
|-----------|-------|-------------------|
| system_architecture_overview | نظرة عامة على العمارة العامة للمنصة (API Gateway → Microservices → Data → External) | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) |
| driver_app_layers | طبقات تطبيق السائق (Presentation → Domain → Data → Infrastructure) | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) |
| dependency_flow | تدفق الاعتماديات (Presentation → Domain ← Data → Infrastructure) | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) |
| feature_first_structure | هيكل كل ميزة (data/، domain/، presentation/) | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |
| lib_structure | هيكل lib/ (core/، shared/، features/) | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) |
| clean_architecture_layers | طبقات العمارة النظيقة (Presentation → Domain → Data → Infrastructure) | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |
| enterprise_platform | المنصة المؤسسية (API Gateway → Microservices → Data → External) | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| multi_vendor | بنية متعدد البائعين | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |

### database/

| اسم الرسم | الوصف | الوثيقة المرجعية |
|-----------|-------|-------------------|
| database_architecture | معمارية قاعدة البيانات (Domain → Data → Infrastructure) | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| database_schema | مخطط قاعدة البيانات (جداول، علاقات) | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| product_catalog_structure | هيكل فهرس المنتجات (Categories → Products → Brands → Suppliers → Units) | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |

### sequence/

| اسم الرسم | الوصف | الوثيقة المرجعية |
|-----------|-------|-------------------|
| delivery_flow | تدفق التسليم النشط (Order Created → Driver Assigned → Pickup → Delivery → Completed) | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| order_status_flow | مراحل حالة الطلب (accepted → at_pickup → picked_up → navigating → at_dropoff → delivered → completed) | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| exception_flow | تدفق الأخطاء (Presentation ← Domain ← Data ← Infrastructure) | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| api_request_flow | تدفق طلب API (UseCase → Repository → DataSource → Dio → Interceptors) | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| offline_sync_flow | تدفق المزامنة غير المتصلة (Queue → Sync → Process) | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |

### deployment/

| اسم الرسم | الوصف | الوثيقة المرجعية |
|-----------|-------|-------------------|
| ci_pipeline | خط معالجة CI (Pull Request → Analysis → Tests → Merge) | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| cd_pipeline | خط معالجة CD (Merge → Build → Integration Tests → Deploy) | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| deployment_environments | بيئات النشر (dev، staging، prod) | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| build_flavors | نكهات البناء (development، staging، production) | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |

### ui/

| اسم الرسم | الوصف | الوثيقة المرجعية |
|-----------|-------|-------------------|
| design_system_components | مكوّنات نظام التصميم (Colors، Typography، Buttons، Cards) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| color_palette | لوحة الألوان (primary، secondary، dark mode) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| typography_scale | مقياس الخطوط (displayLarge → bodySmall) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| button_styles | أنماط الأزرار (Primary، Secondary، Text، Icon) | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| offline_ui | مؤشرات UI غير المتصل (Offline Banner، Sync Indicator، Stale Indicator) | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| error_display | عرض الأخطاء (SnackBar، Dialog، Inline) | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) |
| testing_pyramid | هرم الاختبار (Unit 70%، Widget 20%، Integration 10%) | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |

---

## 🖼️ الصور (docs/images/)

### branding/

| اسم الصورة | الوصف |
|------------|-------|
| saeq_logo | شعار المشروع |
| saeq_logo_dark | شعار المشروع للوضع الليلي |
| saeq_splash | شاشة البدء |

### ui/

| اسم الصورة | الوصف | الوثيقة المرجعية |
|------------|-------|-------------------|
| ui_colors | لوحة الألوان | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| ui_typography | مقياس الخطوط | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| ui_buttons | أنماط الأزرار | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| ui_cards | أنماط البطاقات | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |

### architecture/

| اسم الصورة | الوصف | الوثيقة المرجعية |
|------------|-------|-------------------|
| architecture_layers | طبقات العمارة | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |
| architecture_flow | تدفق العمارة | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) |
| enterprise_platform | المنصة المؤسسية | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |

### screenshots/

| اسم الصورة | الوصف |
|------------|-------|
| welcome_screen | شاشة الترحيب |
| orders_list | قائمة الطلبات |
| delivery_flow | تدفق التسليم |
| profile_screen | شاشة الملف الشخصي |

### icons/

| اسم الأيقونة | الوصف |
|-------------|-------|
| icon_app | أيقونة التطبيق |
| icon_notification | أيقونة الإشعارات |
| icon_delivery | أيقونة التوصيل |
| icon_profile | أيقونة الملف الشخصي |

---

## إضافة رسم أو صورة جديدة

عند إضافة رسم أو صورة جديدة:

1. ضعه في المجلد الصحيح داخل `docs/diagrams/` أو `docs/images/`.
2. أضفه إلى هذا الفهرس.
3. اربطه من الوثيقة المناسبة باستخدام المسار النسبي.
4. تأكد من أن الرابط يعمل.

---

## انظر أيضًا

- [24_INDEX.md](./24_INDEX.md) — فهرس المشروع
- [27_DECISION_TREE.md](./27_DECISION_TREE.md) — شجرة القرارات
- [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — المرجع الرسمي للمشروع

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
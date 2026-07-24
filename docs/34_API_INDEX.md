# SAEQ — API Index

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Review Date:** 2026-07-23  
> **Next Review:** 2027-01-23  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## فهرس واجهات برمجة التطبيقات

يجمع هذا الملف جميع خدمات النظام وواجهات برمجة التطبيقات (APIs) المستخدمة في مشروع SAEQ.

---

### 1. نقاط API الرئيسية

| Method | Endpoint | Description | الوثيقة المرجعية |
|--------|----------|-------------|-------------------|
| POST | `/api/v1/auth/login` | تسجيل الدخول | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/auth/register` | تسجيل سائق جديد | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/auth/refresh` | تجديد الرمز | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/auth/logout` | إنهاء الجلسة | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| GET | `/api/v1/orders` | قائمة الطلبات | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| GET | `/api/v1/orders/{id}` | تفاصيل الطلب | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/orders/{id}/accept` | قبول الطلب | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/orders/{id}/reject` | رفض الطلب | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/deliveries/start` | بدء التسليم | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/deliveries/{id}/pickup` | تأكيد الاستلام | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| POST | `/api/v1/deliveries/{id}/deliver` | تأكيد التسليم | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| GET | `/api/v1/health` | فحص صحة الخادم | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |

---

### 2. خدمات النظام

| الخدمة | الوصف | الوثيقة المرجعية |
|--------|-------|-------------------|
| **Auth Service** | إدارة المصادقة والجلسات | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **Order Service** | إدارة الطلبات | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| **Driver Service** | إدارة حالة السائق والموقع | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| **Delivery Service** | محرك التسليم النشط | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| **Catalog Service** | فهرس المنتجات المركزي | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **Wholesale Service** | سوق الجملة | [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) |
| **Payment Service** | معالجة المدفوعات | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| **Notification Service** | الإشعارات (Push، SMS، WhatsApp) | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **Tracking Service** | تتبع الموقع في الوقت الحقيقي | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| **AI Service** | خدمات الذكاء الاصطناعي | [21_AI_ROADMAP.md](./21_AI_ROADMAP.md) |
| **Admin Service** | لوحة التحكم الإدارية | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |

---

### 3. طبقة API (Client)

| المكوّن | الوصف | الوثيقة المرجعية |
|---------|-------|-------------------|
| **ApiClient** | عميل HTTP على أساس Dio | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **AuthInterceptor** | إضافة JWT وتجديد الرموز | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **LoggingInterceptor** | تسجيل الطلبات (بدون بيانات حساسة) | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **RetryInterceptor** | إعادة المحاولة مع backoff أسي | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **ErrorInterceptor** | التقاط وتحويل أخطاء API | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **ApiService** | عميل Retrofit نوعي | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |

---

### 4. إعدادات API

| الإعداد | القيمة | الوثيقة المرجعية |
|--------|--------|-------------------|
| **Base URL** | `https://api.saeq.example` | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **Connect Timeout** | 30000 ms | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **Receive Timeout** | 30000 ms | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **Send Timeout** | 30000 ms | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **Content-Type** | application/json | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **Accept-Language** | ar (افتراضي) | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **X-App-Version** | إصدار التطبيق | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **X-Platform** | نظام التشغيل | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |

---

### 5. إصدار واجهة برمجة التطبيقات

| الإصدار | الحالة | تاريخ الإيقاف | الوثيقة المرجعية |
|--------|--------|---------------|-------------------|
| v1 | نشط | — | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| v2 | غير مخطط | — | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |

---

### 6. المصادقة والتفويض

| الخدمة | الوصف | الوثيقة المرجعية |
|--------|-------|-------------------|
| **JWT** | توكن مصادقة قياسي | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **Refresh Token** | تجديد الرموز منتهية الصلاحية | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **Biometric Auth** | المصادقة البيومترية (Face ID، Touch ID) | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **RBAC** | التحكم في الوصول على أساس الأدوار | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **Session Timeout** | مهلة جلسة 30 دقيقة | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |

---

## انظر أيضًا

- [35_DATABASE_INDEX.md](./35_DATABASE_INDEX.md) — فهرس قاعدة البيانات
- [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) — معمارية واجهات برمجة التطبيقات
- [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) — دليل الأمان
- [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — المرجع الرسمي للمشروع

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
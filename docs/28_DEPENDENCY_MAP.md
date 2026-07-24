# SAEQ — Dependency Map

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Review Date:** 2026-07-23  
> **Next Review:** 2027-01-23  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## خريطة اعتماد الوثائق

توضح هذه الصفحة كيف تعتمد جميع وثائق المشروع على بعضها. اقرأ الملفات من الأعلى إلى الأسفل لفهم الترابط.

---

### السلسلة الرئيسية (Core Chain)

```
00_PROJECT_BIBLE.md
        ↓
01_BUSINESS_VISION.md
        ↓
02_SYSTEM_ARCHITECTURE.md
        ↓
04_CLEAN_ARCHITECTURE.md
        ↓
05_FOLDER_STRUCTURE.md
        ↓
06_CODING_STANDARDS.md
        ↓
07_NAMING_CONVENTION.md
        ↓
08_UI_DESIGN_SYSTEM.md
        ↓
09_DATABASE_ARCHITECTURE.md
        ↓
13_API_ARCHITECTURE.md
        ↓
14_SECURITY_GUIDE.md
        ↓
17_ERROR_HANDLING.md
        ↓
18_TESTING_GUIDE.md
        ↓
19_DEPLOYMENT_GUIDE.md
```

---

### الفروع الجانبية (Side Branches)

```
00_PROJECT_BIBLE.md
        ↓
03_ENTERPRISE_ARCHITECTURE.md
        ├── 10_PRODUCT_CATALOG_ARCHITECTURE.md
        │       ├── 09_DATABASE_ARCHITECTURE.md
        │       ├── 13_API_ARCHITECTURE.md
        │       └── 22_SAUDI_COMPLIANCE.md
        ├── 11_WHOLESALE_MARKET_ARCHITECTURE.md
        │       ├── 10_PRODUCT_CATALOG_ARCHITECTURE.md
        │       ├── 09_DATABASE_ARCHITECTURE.md
        │       ├── 13_API_ARCHITECTURE.md
        │       └── 22_SAUDI_COMPLIANCE.md
        ├── 12_DELIVERY_ENGINE.md
        │       ├── 13_API_ARCHITECTURE.md
        │       ├── 09_DATABASE_ARCHITECTURE.md
        │       ├── 22_SAUDI_COMPLIANCE.md
        │       └── 15_OFFLINE_GUIDE.md
        ├── 14_SECURITY_GUIDE.md
        │       ├── 13_API_ARCHITECTURE.md
        │       ├── 17_ERROR_HANDLING.md
        │       └── 22_SAUDI_COMPLIANCE.md
        ├── 15_OFFLINE_GUIDE.md
        │       ├── 09_DATABASE_ARCHITECTURE.md
        │       ├── 13_API_ARCHITECTURE.md
        │       └── 12_DELIVERY_ENGINE.md
        ├── 16_LOGGING_GUIDE.md
        │       ├── 14_SECURITY_GUIDE.md
        │       ├── 17_ERROR_HANDLING.md
        │       └── 15_OFFLINE_GUIDE.md
        ├── 20_DEVELOPMENT_ROADMAP.md
        │       ├── 21_AI_ROADMAP.md
        │       ├── 19_DEPLOYMENT_GUIDE.md
        │       └── 22_SAUDI_COMPLIANCE.md
        ├── 21_AI_ROADMAP.md
        │       ├── 20_DEVELOPMENT_ROADMAP.md
        │       ├── 14_SECURITY_GUIDE.md
        │       └── 22_SAUDI_COMPLIANCE.md
        └── 22_SAUDI_COMPLIANCE.md
                ├── 10_PRODUCT_CATALOG_ARCHITECTURE.md
                ├── 11_WHOLESALE_MARKET_ARCHITECTURE.md
                ├── 12_DELIVERY_ENGINE.md
                └── 14_SECURITY_GUIDE.md
```

---

### جدول الاعتماديات التفصيلي

| الملف | يعتمد على | يُعتمم عليه من قبل |
|-------|-----------|-------------------|
| **00_PROJECT_BIBLE.md** | — | جميع الوثائق |
| **01_BUSINESS_VISION.md** | 00 | 02، 03 |
| **02_SYSTEM_ARCHITECTURE.md** | 00، 01، 04 | 03، 05، 06، 09، 13، 14، 15 |
| **03_ENTERPRISE_ARCHITECTURE.md** | 00 | 10، 11، 12، 14، 15، 20، 21، 22 |
| **04_CLEAN_ARCHITECTURE.md** | 00، 02 | 02، 05، 06، 09، 13 |
| **05_FOLDER_STRUCTURE.md** | 00، 04 | 06، 07، 08 |
| **06_CODING_STANDARDS.md** | 00، 07 | 05، 08، 17، 18، 13، 09 |
| **07_NAMING_CONVENTION.md** | 00، 06 | 05، 06، 08 |
| **08_UI_DESIGN_SYSTEM.md** | 00، 06 | 05 |
| **09_DATABASE_ARCHITECTURE.md** | 00، 02 | 02، 10، 11، 12، 13، 15 |
| **10_PRODUCT_CATALOG_ARCHITECTURE.md** | 00 | 03، 11، 22 |
| **11_WHOLESALE_MARKET_ARCHITECTURE.md** | 00 | 03، 22 |
| **12_DELIVERY_ENGINE.md** | 00 | 03، 22 |
| **13_API_ARCHITECTURE.md** | 00 | 02، 04، 09، 14، 15 |
| **14_SECURITY_GUIDE.md** | 00 | 02، 03، 06، 13، 17، 21، 22 |
| **15_OFFLINE_GUIDE.md** | 00 | 09، 12، 13 |
| **16_LOGGING_GUIDE.md** | 00 | 14، 17 |
| **17_ERROR_HANDLING.md** | 00 | 06، 14، 16 |
| **18_TESTING_GUIDE.md** | 00 | 06، 19 |
| **19_DEPLOYMENT_GUIDE.md** | 00 | 18 |
| **20_DEVELOPMENT_ROADMAP.md** | 00 | 21، 22 |
| **21_AI_ROADMAP.md** | 00 | 20، 22 |
| **22_SAUDI_COMPLIANCE.md** | 00 | 03، 10، 11، 12، 14 |
| **23_CHANGELOG.md** | 00 | — |
| **24_INDEX.md** | 00 | — |
| **25_GLOSSARY.md** | 00 | — |
| **26_ABBREVIATIONS.md** | 00 | — |
| **27_DECISION_TREE.md** | 00 | — |
| **28_DEPENDENCY_MAP.md** | 00 | — |
| **29_DOCUMENT_CHECKLIST.md** | 00 | — |
| **30_DIAGRAM_INDEX.md** | 00 | — |
| **31_TRACEABILITY_MATRIX.md** | 00 | — |
| **32_KNOWN_LIMITATIONS.md** | 00 | — |
| **33_SECURITY_INDEX.md** | 00 | 14 |
| **34_API_INDEX.md** | 00 | 13 |
| **35_DATABASE_INDEX.md** | 00 | 09 |

---

## انظر أيضًا

- [24_INDEX.md](./24_INDEX.md) — فهرس المشروع
- [27_DECISION_TREE.md](./27_DECISION_TREE.md) — شجرة القرارات
- [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — المرجع الرسمي للمشروع

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
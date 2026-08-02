# المرحلة الرابعة — توجيه تنفيذي ملزم (Device QA)

> **تاريخ التفعيل:** 2026-08-02  
> **الحالة:** ACTIVE — العمل الوحيد المسموح على المشروع حتى اكتمال Device QA  
> **التاجر:** محظور بالكامل حتى اكتمال المراحل 4→10 + موافقة المالك

## 1) ممنوع أثناء Device QA

- أي Feature جديدة  
- أي Refactoring  
- أي تحسينات UI / تغيير تصميم  
- أي تغيير للعقود / Backend / Database  

**يُسمح فقط:** تنفيذ الاختبارات، التوثيق، وإصلاح Bug يظهر أثناء Device QA.

## 2) تسلسل إصلاح FAIL (بدون استثناء)

1. تسجيل الخطأ  
2. إنشاء Issue  
3. تحديد السبب  
4. إصلاح أقل قدر ممكن  
5. مراجعة الكود  
6. إعادة اختبار البند  
7. Regression للمسار المتأثر  

## 3) معايير PASS

السلوك المتوقع كامل · لا Crash · لا Freeze · لا أخطاء Console مؤثرة · لا سلوك غير متوقع · توثيق النتيجة.

## 4) معايير FAIL

Crash · Exception · Timeout · Loading لا ينتهي · UI خاطئة · Navigation خاطئة · بيانات غير صحيحة · Geofence/GPS غير صحيح · إعادة اتصال لا تعمل · Session تضيع · Logout غير صحيح.

## 5) توثيق كل حالة

رقم الحالة · الاسم · Build Number · الجهاز · Android · وقت التنفيذ · PASS/FAIL · ملاحظات · Screenshot/Video عند الفشل.

## 6) بعد Device QA

لا انتقال للإطلاق مباشرة. بالترتيب الإلزامي:

1. Performance Review  
2. Security Review  
3. Code Quality Review  
4. ثم فقط: Documentation Freeze → RC → Final Release Review  

## 7) بوابة PR #27

يبقى معلقًا عمدًا حتى: نجاح بنود Device QA المتعلقة به · لا Regression · مراجعة كود نهائية · موافقة الدمج. ثم تحقق سريع أن `main` يعكس الحالة المختبرة.

## 8) قرار الإدارة

تطبيق التاجر محظور حتى: Device QA + Performance + Security + Code Quality + التوثيق + RC + إغلاق #27 + موافقة المالك النهائية.

# STEP 3B — إصلاح توافق Android Build المرتبط بـ connectivity_plus

**المرحلة:** PROJECT STABILIZATION
**نوع الخطوة:** إصلاح محدود النطاق (Android Build Compatibility) — بدون تشخيص Runtime
**التاريخ:** 2026-07-24
**التقرير المرجعي المعتمد:** `docs/STABILIZATION_STEP_03A_FIRST_RUNTIME_DIAGNOSIS.md`

---

## 1. السبب الجذري المؤكد

حزمة `connectivity_plus` بجميع إصدارات سلسلة **5.x** (بما فيها 5.0.2 المستخدم فعلياً) تحتوي على قيمة **`compileSdkVersion 33`** مكتوبة بشكل صريح وثابت داخل ملف Gradle الخاص بها (`android/build.gradle`)، وهذا مؤكَّد من CHANGELOG الرسمي للحزمة الذي يذكر في إصدار 5.0.0:

> `FIX(connectivity_plus): Revert bump compileSDK to 34 (#2229)`

أي أن الفريق المطوّر **تراجع عمداً** عن رفع compileSdk في كل سلسلة 5.x. في المقابل، تبعيات AndroidX الحديثة التي يجرها المشروع بشكل تبعي (`androidx.fragment:1.7.1`, `androidx.window:1.2.0`, `androidx.activity:1.8.1`, `androidx.lifecycle:*:2.7.0`, `androidx.core:1.13.1`, ...) تتطلب أن يكون أي موديول يعتمد عليها مبنياً بـ `compileSdk 34` أو أعلى. هذا التعارض تسبب في فشل مهمة Gradle:

```
Execution failed for task ':connectivity_plus:checkDebugAarMetadata'.
```

وهو نفس الخطأ الموثّق في STEP 3A.

---

## 2. نسخ Flutter و Dart و Java

تم الفحص عبر `flutter --version` والتحقق من JDK الفعلي المستخدم في Gradle Daemon (كما ظهر في سجلات التشغيل السابقة):

| الأداة | القيمة |
|---|---|
| Flutter | 3.44.7 (channel stable) |
| Dart | 3.12.2 |
| JDK المستخدم فعلياً بواسطة Gradle | OpenJDK 21.0.10 (JBR المرفق مع Android Studio) |
| Java Compatibility في المشروع (compileOptions / kotlin jvmTarget) | 17 (كما هو، **لم يتغيّر**) |

لم يتم تعديل أي من هذه القيم؛ JDK 21 قادر على بناء أهداف Java 17 دون مشكلة، وهذا كان قائماً بالفعل قبل هذه الخطوة.

---

## 3. compileSdk و targetSdk و minSdk — قبل وبعد

### موديول التطبيق (`android/app/build.gradle.kts`)

| القيمة | قبل | بعد |
|---|---|---|
| `compileSdk` | `flutter.compileSdkVersion` (= 36 في نسخة Flutter الحالية) | **لم يتغيّر** |
| `targetSdk` | `flutter.targetSdkVersion` | **لم يتغيّر** |
| `minSdk` | `flutter.minSdkVersion` | **لم يتغيّر** |

موديول التطبيق نفسه **لم يكن هو مصدر المشكلة إطلاقاً** (compileSdk الافتراضي فيه 36، وهو أعلى من الحد المطلوب 34)، ولذلك لم تكن هناك أي حاجة لتعديل `android/app/build.gradle.kts`.

### موديول الحزمة `connectivity_plus` (داخل الحزمة نفسها، لم نُعدّله يدوياً)

| القيمة | قبل (5.0.2) | بعد (6.1.5) |
|---|---|---|
| `compileSdk` | 33 | 34 |
| `minSdk` | 19 | 19 (لم يتغيّر) |
| `sourceCompatibility`/`targetCompatibility` | Java 17 | Java 17 (لم يتغيّر) |

هذا التغيير حدث **تلقائياً كنتيجة لترقية الحزمة**، وليس نتيجة تعديل يدوي من طرفنا على أي ملف Gradle.

---

## 4. Android Gradle Plugin (AGP) — قبل وبعد

| | قبل | بعد |
|---|---|---|
| AGP (المشروع، `android/settings.gradle.kts`) | 9.0.1 | **لم يتغيّر — 9.0.1** |

الحد الأدنى المطلوب من `connectivity_plus 6.1.5` هو AGP `>= 8.3.0`. نسخة المشروع الحالية (9.0.1) أعلى بالفعل من هذا الحد، فلم تكن هناك حاجة لأي تحديث.

---

## 5. Gradle — قبل وبعد

| | قبل | بعد |
|---|---|---|
| Gradle Wrapper (`gradle-wrapper.properties`) | 9.1.0 | **لم يتغيّر — 9.1.0** |

الحد الأدنى المطلوب من `connectivity_plus 6.1.5` هو Gradle `>= 8.4`. النسخة الحالية (9.1.0) أعلى بالفعل من هذا الحد.

---

## 6. Kotlin — قبل وبعد

| | قبل | بعد |
|---|---|---|
| Kotlin (`android/settings.gradle.kts`) | 2.3.20 | **لم يتغيّر — 2.3.20** |

لا يوجد أي متطلب Kotlin صريح من `connectivity_plus 6.1.5` يتجاوز ما هو موجود حالياً؛ لم تكن هناك حاجة لأي تعديل.

> **الخلاصة العامة لهذا القسم:** لم يتم تحديث AGP أو Gradle أو Kotlin أو compileSdk لموديول التطبيق إطلاقاً في هذه الخطوة، لأن بيئة المشروع الحالية كانت **أعلى بالفعل** من كل الحدود الدنيا المطلوبة. الحل تركّز حصراً على ترقية حزمة `connectivity_plus` نفسها.

---

## 7. connectivity_plus — قبل وبعد

| | قبل | بعد |
|---|---|---|
| القيد في `pubspec.yaml` | `^5.0.0` | `6.1.5` (إصدار محدد وثابت، وليس نطاقاً) |
| الإصدار المحلول فعلياً (`pubspec.lock`) | 5.0.2 | 6.1.5 |
| `connectivity_plus_platform_interface` (تبعية فرعية) | 1.2.4 | 2.1.0 |

تم استخدام إصدار محدد (`6.1.5`) بدلاً من نطاق (`^6.1.5` أو أوسع) لمنع حل أي إصدار آخر تلقائياً (مثل 7.x) أثناء مرحلة الاستقرار الحالية، بما يتوافق مع تعليمات هذه الخطوة.

---

## 8. سبب اختيار الإصدار النهائي (6.1.5)

1. تم استبعاد **الخيار A** (البقاء ضمن سلسلة 5.x) بشكل قاطع: كل إصدارات 5.x — وليس فقط 5.0.2 — تحمل `compileSdkVersion 33` بثبات، وهذا مؤكَّد رسمياً من نص CHANGELOG (تراجع متعمد عن compileSdk 34 في 5.0.0 نفسها). لا يوجد أي إصدار 5.x يحل المشكلة.
2. تم فحص **الخيار B** (آخر إصدار مستقر من سلسلة 6.1.x = **6.1.5**) ومطابقة متطلباته الرسمية المنشورة على pub.dev:
   - Flutter `>= 3.19.0` → المشروع على 3.44.7 ✅
   - Dart `>= 3.3.0 < 4.0.0` → المشروع على 3.12.2 ✅
   - Android `compileSDK 34` → موديول التطبيق أصلاً على 36 ✅
   - Java 17 → مطابق تماماً لما هو مضبوط في المشروع ✅
   - AGP `>= 8.3.0` → المشروع على 9.0.1 ✅
   - Gradle wrapper `>= 8.4` → المشروع على 9.1.0 ✅

   **جميع الشروط متحققة دون أي حاجة لأي ترقية إضافية في أدوات البناء**، وهذا يجعل 6.1.5 الخيار الأمثل عملياً بمبدأ "أقل تغييرات ممكنة".
3. تم بذلك تجاوز الحاجة لفحص **الخيار C** (6.0.1) بشكل منفصل، لأن 6.1.5 لا يفرض أي حد أدنى إضافي في أدوات البناء يزيد عمّا يفرضه 6.0.1، بينما يحمل إصلاحات لاحقة أكثر استقراراً على مستوى أندرويد (انظر البند 9).
4. **الخيار D (7.x) لم يُستخدم إطلاقاً**، بالرغم من أن بيئة المشروع الحالية تتجاوز فعلياً الحد الذي وضعته التعليمات لفتحه (AGP ≥ 8.12.1، Gradle ≥ 8.13، Kotlin ≥ 2.2.0)، لأن ذلك غير ضروري: 6.1.5 يحل المشكلة بالكامل، ولا مبرر للترقية إلى إصدار أحدث "لمجرد أنه الأحدث"، تماشياً مع أولوية التعليمات الثانية بالحرف.

---

## 9. سبب رفض الإصدارات الأخرى

- **رفض كل سلسلة 5.x:** غير قابلة للاستخدام إطلاقاً — المشكلة بنيوية في الحزمة نفسها (compileSdk 33 ثابت بقرار متعمد من المطورين)، وليست مشكلة عرضية يمكن حلها برفع رقم إصدار ثانوي (patch) ضمن السلسلة نفسها.
- **رفض 6.0.1 تحديداً (الخيار C):** وإن كان يحل مشكلة compileSdk بنفس الطريقة، فهو أول إصدار من سلسلة 6.x وتضمّن مشاكل معروفة أُصلحت لاحقاً على مستوى أندرويد (مثل: "Fix connectivity state update on Android when network is lost"، و"Emit event with types on Android when subscribing to onConnectivityChanged"، و"Return valid connection type when only one available"). بما أن 6.1.5 لا يضيف أي متطلب بناء إضافي فوق 6.0.1، فلا يوجد أي سبب منطقي لتفضيل 6.0.1 الأقل استقراراً على 6.1.5 الأحدث ضمن نفس خط الإصدارات الرئيسي (6.x) ونفس متطلبات البيئة.
- **رفض 7.x (الخيار D):** لأنه غير ضروري بالمرة؛ الانتقال إليه كان سيضيف نطاق تغيير أكبر (Dart SDK constraint أضيق، تغييرات إضافية في الحزمة كـ `hasConnectivity` extension وقيمة `satellite` جديدة في `ConnectivityResult`) دون أي فائدة حقيقية تخص مشكلة compileSdk المطلوب حلها هنا. القاعدة الصريحة في التعليمات (D ممنوعة إلا عند الضرورة) طُبّقت حرفياً.

---

## 10. هل تغيّر API الخاص بـ connectivity_plus؟

**نعم.** بدءاً من الإصدار 6.0.0 (وهو تغيير كسور رسمي محتفظ به في 6.1.5)، أصبحت الدوال التالية تُرجع **قائمة** بدلاً من قيمة مفردة:

- `Connectivity().checkConnectivity()` → كانت `Future<ConnectivityResult>`، أصبحت `Future<List<ConnectivityResult>>`.
- `Connectivity().onConnectivityChanged` → كان `Stream<ConnectivityResult>`، أصبح `Stream<List<ConnectivityResult>>`.

هذا التغيير يعكس دعم اكتشاف أكثر من نوع اتصال فعّال في نفس الوقت (مثل WiFi + VPN معاً).

---

## 11. الملفات التي تم تعديلها

تم تعديل **ملفين فقط** في كامل المشروع:

1. **`pubspec.yaml`** — سطر واحد: تغيير قيد `connectivity_plus` من `^5.0.0` إلى إصدار محدد `6.1.5`.
2. **`lib/core/network/network_monitor.dart`** — تعديل داخلي محدود لاستيعاب `List<ConnectivityResult>` (تفصيل في البند التالي).

لم يتم تعديل أي ملف Gradle أو Android آخر (`android/app/build.gradle.kts`، `android/build.gradle.kts`، `android/settings.gradle.kts`، `gradle-wrapper.properties`، `gradle.properties`، `AndroidManifest.xml`) لأن جميعها كانت متوافقة بالفعل مسبقاً.

---

## 12. هل تم تعديل NetworkMonitor؟

**نعم، بأقل تغيير ممكن، دون إعادة تصميم الكلاس:**

- تغيير نوع الحقل الداخلي `_connectionType` من `ConnectivityResult` إلى `List<ConnectivityResult>` (القيمة الابتدائية: `[ConnectivityResult.none]`).
- تغيير نوع `_subscription` من `StreamSubscription<ConnectivityResult>?` إلى `StreamSubscription<List<ConnectivityResult>>?`.
- تغيير توقيع الدالة الخاصة `_handleConnectivityChange` لتستقبل `List<ConnectivityResult>` بدلاً من قيمة مفردة.
- إضافة دالة مساعدة خاصة واحدة فقط: `_hasConnection(List<ConnectivityResult> results)` تُعيد `true` إذا كان أي عنصر في القائمة **ليس** `ConnectivityResult.none`.
- تحديث `checkConnectivity()` لاستخدام `_hasConnection(...)` بدلاً من المقارنة المباشرة `!= ConnectivityResult.none`.
- تحديث getter العام `connectionType` لإعادة `List<ConnectivityResult>` بدلاً من قيمة مفردة (لا يوجد أي مستدعٍ آخر لهذا الـ getter في المشروع بأكمله — تم التأكد عبر بحث شامل في `lib/` و`test/` قبل التعديل).

**تم الحفاظ الكامل على المعنى المطلوب:**
- `none` (أو قائمة تحتوي فقط على `none`) = لا يوجد اتصال.
- وجود أي عنصر آخر غير `none` في القائمة = اتصال متاح على مستوى نظام التشغيل.
- لم تتم معاملة وجود اتصال كإثبات على توفر إنترنت فعلي (لم يتغيّر هذا السلوك، ولا علاقة لـ `connectivity_plus` به أصلاً).

لم تُعدَّل أي واجهة عامة أخرى (`status`, `isOnline`, `isOffline`, `statusStream`, `init()`, `dispose()`) ولم تتم إضافة أي منطق جديد خارج نطاق استيعاب التغيير في نوع القيمة المُعادة من الحزمة.

---

## 13. نتيجة flutter pub get

**نجح.**

```
> connectivity_plus 6.1.5 (was 5.0.2) (7.3.1 available)
> connectivity_plus_platform_interface 2.1.0 (was 1.2.4)
Changed 2 dependencies!
```

تغيّرت حزمتان فقط، ولم تتأثر أي حزمة أخرى في المشروع (بما فيها `sqlite3_flutter_libs`, `drift`, `dio`, إلخ).

---

## 14. نتيجة flutter analyze

**0 Errors** (النتيجة المطلوبة محققة).

```
35 issues found. (ran in 48.7s)
```

جميع الـ 35 مشكلة هي **Warnings + Info فقط** (7 تحذيرات + 28 معلومة)، وهي **نفس العدد الإجمالي تماماً** الموجود في `STABILIZATION_STEP_02F_FINAL_COMPILATION_RECOVERY.md` قبل هذه الخطوة. أي لم تُستحدَث أي مشكلة جديدة (تحذير أو معلومة) نتيجة تعديل `network_monitor.dart` أو ترقية الحزمة. لم تتم معالجة أي Warning أو Info، حسب التعليمات.

---

## 15. نتيجة flutter test

**جميع الاختبارات ناجحة (3/3):**

```
00:00 +0: loading .../test/widget_test.dart
00:00 +0: Welcome screen renders
00:01 +1: App bootstrap smoke test
00:01 +2: Welcome screen has required elements
00:01 +3: All tests passed!
```

---

## 16. نتيجة flutter build apk --debug

**فشل — لكن لسبب مختلف تماماً عن مشكلة connectivity_plus الأصلية، وخارج نطاق هذه الخطوة.**

تم تنفيذ الأمر مرتين للتأكد من قابلية التكرار، وظهرت **نفس النتيجة بالضبط** في كل مرة:

```
* What went wrong:
Execution failed for task ':app:compileFlutterBuildDebug'.
...
Bad state: Hash of downloaded file libsqlite3.arm64.android.so is
bef140a1a96994029153dca8c00b1750b9a5a764fb9db2dc68d7bb40e8a29e8a, expected
e99515af1d7119fb61843ae5e597344e7f258563de3a7e5a3869f627aab2887b.
  Building assets for package:sqlite3 failed.
  build.dart returned with exit code: 255.
```

**النقطة الأهم:** هذا الفشل حدث في مرحلة لاحقة تماماً عن نقطة الفشل الأصلية في STEP 3A. مهمة Gradle `:connectivity_plus:checkDebugAarMetadata` **لم تظهر إطلاقاً** ولم يتكرر أي خطأ متعلق بـ `compileSdk` أو `AAR metadata` أو `connectivity_plus`، مما يؤكد أن **مشكلة connectivity_plus محلولة بالكامل**. الفشل الجديد يخص حزمة `sqlite3` (تبعية غير مباشرة عبر `sqlite3_flutter_libs` التي يستخدمها Drift): فشل تنزيل ملف native مُجمّع مسبقاً (`libsqlite3.arm64.android.so`) بسبب عدم تطابق قيمة SHA-256 المتوقعة، بشكل ثابت ومتكرر (نفس القيمتين تماماً في المحاولتين).

**التزاماً بحدود هذه الخطوة الصريحة** ("مخصصة حصراً لإصلاح توافق Android Build المرتبط بـ connectivity_plus"، "لا توسّع تحديثات Android خارج الحد الضروري")، **لم يتم لمس أي شيء متعلق بـ `sqlite3` أو `sqlite3_flutter_libs` أو أي حزمة أخرى في هذه الخطوة**. هذه المشكلة موثّقة هنا بشكل شفاف لتُعالَج في خطوة منفصلة لاحقة بقرار من فريق الإدارة.

---

## 17. هل تم تثبيت التطبيق؟

**لا.** لم يُبنَ ملف APK بنجاح (بسبب مشكلة sqlite3 المذكورة أعلاه)، فلم تكن هناك أي فرصة للتثبيت على الجهاز.

---

## 18. هل بدأ التطبيق في الفتح؟

**لا.** حسب تعليمات هذه الخطوة، تنفيذ `flutter run -d AP4EVB6423004646` مشروط بنجاح `flutter build apk --debug` أولاً. بما أن البناء فشل، **لم يتم تنفيذ `flutter run` في هذه الخطوة إطلاقاً.**

---

## 19. أي Runtime Exception ظهر بعد الفتح (دون إصلاحه)

**لا ينطبق.** لم يُفتح التطبيق على الجهاز في هذه الخطوة.

---

## 20. أي مخاطر توافق متبقية

1. **الخطر الوحيد المكتشف فعلياً:** فشل تنزيل/تحقق `sqlite3` native asset (`libsqlite3.arm64.android.so`) بسبب عدم تطابق SHA-256، وهو **يحجب أي بناء APK ناجح حالياً**، بشكل مستقل تماماً عن `connectivity_plus`. هذا يحتاج خطوة تشخيص/إصلاح منفصلة (تخص حزمة `sqlite3` / `sqlite3_flutter_libs` أو بيئة الشبكة المستخدمة في التنزيل).
2. **لا توجد أي مخاطر توافق متبقية تخص `connectivity_plus` نفسه** بعد الترقية إلى 6.1.5: تم فحص AGP/Gradle/Kotlin/Java/compileSdk بدقة، وجميعها متوافقة دون أي حاجة لتحديث إضافي، ولم يظهر أي خطأ متعلق بها في محاولتي البناء.
3. القيد المحدد (`connectivity_plus: 6.1.5` بدون نطاق) يمنع أي ترقية تلقائية غير مقصودة لاحقاً أثناء الاستقرار، لكنه يتطلب مراجعة يدوية عند الحاجة لاحقاً لأي ترقية مستقبلية (وهذا مقصود ومطلوب في هذه المرحلة).

---

## 21. هل استُخدم dependency_overrides؟

**لا.** لم تكن هناك أي حاجة لاستخدامه؛ تم حل مشكلة `connectivity_plus` عبر ترقية طبيعية ومباشرة للحزمة في `pubspec.yaml` فقط، وهو الحل الرسمي المفضّل حسب تعليمات هذه الخطوة.

---

## 22. هل تم تعديل .pub-cache؟

**لا.** لم يتم تعديل أو حذف أو إنشاء أي ملف داخل `.pub-cache`. تمت قراءة ملفين فقط (بشكل قراءة فقط دون أي كتابة) للتحقق من السبب الجذري:
- `connectivity_plus-5.0.2/android/build.gradle` (لتأكيد compileSdk 33).
- `connectivity_plus-6.1.5/android/build.gradle` (لتأكيد compileSdk 34 بعد الترقية).

---

## 23. درجة الثقة في الحل

- **بخصوص إصلاح مشكلة connectivity_plus/compileSdk تحديداً (وهو نطاق هذه الخطوة):** درجة ثقة **98%**. تم تأكيد تجاوز نقطة الفشل الأصلية (`:connectivity_plus:checkDebugAarMetadata`) بشكل كامل في كل من محاولتي `flutter build apk --debug`، ولم تظهر أي رسالة خطأ متعلقة بـ compileSdk أو AAR metadata أو connectivity_plus بعد الترقية. النسبة المتبقية من عدم اليقين (2%) مرتبطة فقط بعدم القدرة على تنفيذ `flutter run` فعلياً على الجهاز للتحقق النهائي 100%، بسبب حاجز sqlite3 المنفصل.
- **بخصوص تحقيق معايير النجاح الكاملة المطلوبة لهذه الخطوة** (تثبيت وتشغيل فعلي للتطبيق): **لم تتحقق**. النجاح متوقف حالياً على حل مشكلة `sqlite3` native asset المكتشفة حديثاً، والتي هي خارج النطاق المحدد صراحةً لهذه الخطوة (connectivity_plus فقط).

---

## خلاصة الحالة الحالية

- ✅ السبب الجذري لمشكلة `connectivity_plus`/`compileSdk` **محلول ومؤكَّد** (ترقية إلى 6.1.5 + تعديل محدود في `NetworkMonitor`).
- ✅ `flutter pub get` نجح، `flutter analyze` = 0 Errors، `flutter test` = 3/3 ناجحة.
- ❌ `flutter build apk --debug` **لم ينجح**، لكن بسبب مشكلة جديدة ومنفصلة تماماً (`sqlite3` native asset hash mismatch)، غير متعلقة بنطاق هذه الخطوة.
- لم يتم تثبيت التطبيق أو فتحه على الجهاز في هذه الخطوة نتيجة لذلك.
- لم يُستخدم `dependency_overrides`، ولم يُعدَّل `.pub-cache`، ولم تُوسَّع أي تحديثات Android خارج الحد الضروري (فعلياً: لم تُحدَّث أي أداة بناء أندرويد إطلاقاً).

**تم إيقاف التنفيذ بعد كتابة هذا التقرير كما هو مطلوب. لم يتم إصلاح أي Runtime Error (لم نصل لهذه المرحلة)، ولم تُعالَج أي Warnings أو Info، ولم تُضَف أي ميزة جديدة.**

**بانتظار توجيه بشأن خطوة منفصلة لتشخيص/إصلاح مشكلة `sqlite3` native asset قبل إمكانية إعادة تنفيذ STEP 3A/3B للتحقق النهائي من التشغيل الفعلي على الجهاز.**

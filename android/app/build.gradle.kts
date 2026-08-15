import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

fun isAndroidReleaseTaskRequested(): Boolean =
    gradle.startParameter.taskNames.any { name ->
        val n = name.lowercase()
        n.contains("release") &&
            (n.contains("assemble") ||
                n.contains("bundle") ||
                n.contains("package") ||
                n.contains("bundleaab"))
    }

fun loadReleaseKeystoreProperties(): Properties {
    val propsFile = rootProject.file("key.properties")
    if (!propsFile.isFile) {
        throw GradleException(
            "W5 release signing refused: missing ${propsFile.path}. " +
                "Copy android/key.properties.example and never commit key.properties or keystores.",
        )
    }
    val props = Properties()
    // Strip UTF-8 BOM if present (common when editing key.properties on Windows).
    val raw = propsFile.readBytes()
    val offset =
        if (raw.size >= 3 &&
            raw[0] == 0xEF.toByte() &&
            raw[1] == 0xBB.toByte() &&
            raw[2] == 0xBF.toByte()
        ) {
            3
        } else {
            0
        }
    props.load(raw.inputStream(offset, raw.size - offset).reader(Charsets.UTF_8))
    val required = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
    for (key in required) {
        val value = props.getProperty(key)?.trim().orEmpty()
        if (value.isEmpty()) {
            throw GradleException("W5 release signing refused: '$key' is empty in key.properties.")
        }
        val lower = value.lowercase()
        if (
            lower == "replace-locally" ||
            lower == "changeme" ||
            lower.contains("placeholder") ||
            lower.contains("your_") ||
            lower == "password" ||
            lower == "alias"
        ) {
            throw GradleException(
                "W5 release signing refused: '$key' still looks like a placeholder.",
            )
        }
    }
    val storePath = props.getProperty("storeFile")!!.trim()
    val storeFile =
        if (file(storePath).isAbsolute) {
            file(storePath)
        } else {
            rootProject.file(storePath)
        }
    if (!storeFile.isFile) {
        throw GradleException(
            "W5 release signing refused: keystore not found at ${storeFile.path}.",
        )
    }
    val pathLower = storeFile.absolutePath.lowercase().replace('\\', '/')
    if (
        storeFile.name.equals("debug.keystore", ignoreCase = true) ||
        pathLower.endsWith("/debug.keystore") ||
        pathLower.contains("/.android/debug.keystore")
    ) {
        throw GradleException(
            "W5 release signing refused: debug.keystore is forbidden for release builds.",
        )
    }
    props.setProperty("_resolvedStoreFile", storeFile.absolutePath)
    return props
}

val releaseRequested = isAndroidReleaseTaskRequested()
val releaseKeystoreProps: Properties? =
    if (releaseRequested) {
        loadReleaseKeystoreProperties()
    } else {
        null
    }

android {
    namespace = "com.saeq.driver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.saeq.driver"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeystoreProps != null) {
            create("release") {
                keyAlias = releaseKeystoreProps.getProperty("keyAlias")
                keyPassword = releaseKeystoreProps.getProperty("keyPassword")
                storeFile = file(releaseKeystoreProps.getProperty("_resolvedStoreFile")!!)
                storePassword = releaseKeystoreProps.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // W5: never fall back to debug signing; fail closed when Release is requested.
            if (releaseKeystoreProps != null) {
                signingConfig = signingConfigs.getByName("release")
            } else if (releaseRequested) {
                throw GradleException("W5 release signing refused: release keystore not configured.")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Read local.properties (gitignored — never committed) ─────────────────────
// Keys injected here never appear in compiled Dart code or version control.
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

// ── Read key.properties (gitignored — never committed) ────────────────────────
// Holds the upload-keystore path/passwords for release signing. Absent on a
// fresh checkout or a CI run without secrets configured yet — release builds
// fall back to debug signing in that case (with a build-time warning) rather
// than failing outright, since not every build needs to be Play-uploadable.
val keyProps = Properties()
val keyPropsFile = rootProject.file("key.properties")
val hasReleaseSigning = keyPropsFile.exists()
if (hasReleaseSigning) {
    keyPropsFile.inputStream().use { keyProps.load(it) }
}

android {
    namespace = "com.sunnahgrandeur.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sunnahgrandeur.app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ── Inject Maps SDK key into AndroidManifest via placeholder ────────
        // AndroidManifest.xml references this as: android:value="${mapsApiKey}"
        // The key is read from local.properties and never hardcoded in source.
        manifestPlaceholders["mapsApiKey"] =
            localProps.getProperty("MAPS_ANDROID_KEY") ?: ""
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "⚠ android/key.properties not found — release build is signed with the " +
                    "DEBUG key and is NOT uploadable to Play Console. See android/key.properties.template."
                )
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications on Android.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

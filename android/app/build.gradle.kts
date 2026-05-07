import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.firebase.crashlytics")
}

// Load release keystore credentials from android/key.properties (gitignored).
// Falls back silently to the debug signing config when the file isn't there
// (so `flutter run --debug` and CI smoke builds still work).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()
    && keystoreProperties.getProperty("storeFile")?.isNotBlank() == true

android {
    namespace = "com.bakemono.businessmindset"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (uses java.time / java.nio
        // classes that aren't present on minSdk < 26 without desugaring).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bakemono.businessmindset"
        // Widget + WorkManager require minSdk 23. Flutter's default is also 23+,
        // but we pin it explicitly so the widget keeps working on every API level
        // we declare support for.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Use the release keystore when key.properties is configured;
            // otherwise fall back to debug keys so the project still builds
            // (you cannot upload a debug-signed AAB to Play, that's expected).
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.core:core-ktx:1.13.1")

    // WorkManager powers the native widget refresh scheduler (see
    // [widget/WidgetRefreshScheduler.kt]) — Android's equivalent of the
    // `Timeline(policy: .after(nextTrigger))` contract on iOS. We use a
    // OneTimeWorkRequest aligned to the next slot and re-enqueue it from
    // the worker, which is the cheapest way to get per-slot refreshes
    // without holding on to exact alarms.
    implementation("androidx.work:work-runtime-ktx:2.9.1")

    // TikTok / attribution SDKs - Google Play Services for Advertising ID.
    implementation("com.google.android.gms:play-services-ads-identifier:18.1.0")

    // Attribution - Google Play Install Referrer API.
    implementation("com.android.installreferrer:installreferrer:2.2")
}

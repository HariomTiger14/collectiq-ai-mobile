plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "google-services.json not found; Firebase Android config is skipped for this build."
    )
}

android {
    namespace = "com.collectiq.ai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.collectiq.ai"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("local") {
            dimension = "environment"
            applicationIdSuffix = ".local"
        }
        create("sit") {
            dimension = "environment"
            applicationIdSuffix = ".sit"
        }
        create("prod") {
            dimension = "environment"
        }
    }

    signingConfigs {
        create("releaseUpload") {
            val storeFilePath = System.getenv("COLLECTIQ_UPLOAD_KEYSTORE")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
                storePassword = System.getenv("COLLECTIQ_UPLOAD_STORE_PASSWORD")
                keyAlias = System.getenv("COLLECTIQ_UPLOAD_KEY_ALIAS")
                keyPassword = System.getenv("COLLECTIQ_UPLOAD_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val hasUploadKeystore =
                !System.getenv("COLLECTIQ_UPLOAD_KEYSTORE").isNullOrBlank()
            signingConfig = if (hasUploadKeystore) {
                signingConfigs.getByName("releaseUpload")
            } else {
                signingConfigs.getByName("debug")
            }
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

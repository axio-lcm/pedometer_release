import java.io.FileInputStream
import java.util.Properties

// 🔐 签名配置：CI自动用Release，本地自动用Debug
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
val hasReleaseSigning = keyPropertiesFile.exists()

if (hasReleaseSigning) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
    println("✅ CI环境: 使用Release签名")
} else {
    println("💻 本地开发: 使用Debug签名")
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val googleMapsApiKey =
    localProperties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: providers.gradleProperty("GOOGLE_MAPS_API_KEY").orNull
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: ""


android {
    namespace = "com.pedometer.step.counter.walking.tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.pedometer.step.counter.walking.tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(26, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }


     signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

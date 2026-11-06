import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties().apply {
    val config = rootProject.file("key.properties")
    if (config.isFile) config.inputStream().use { load(it) }
}

android {
    namespace = "com.example.sample_aplikasi"
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
        // Keep the original ID on development devices; release uses the Play listing ID.
        applicationId = "com.example.sample_aplikasi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("upload") {
            storeFile = releaseProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = releaseProperties.getProperty("storePassword")
            keyAlias = releaseProperties.getProperty("keyAlias")
            keyPassword = releaseProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("upload")
        }
    }
}

androidComponents.onVariants(androidComponents.selector().withBuildType("release")) { variant ->
    variant.applicationId.set(releaseProperties.getProperty("applicationId", "site.markazarabiyah.siakad"))
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        require(listOf("storeFile", "storePassword", "keyAlias", "keyPassword", "applicationId")
            .all { !releaseProperties.getProperty(it).isNullOrBlank() }) {
            "Lengkapi android/key.properties sesuai key.properties.example sebelum membuat rilis."
        }
    }
}

flutter {
    source = "../.."
}

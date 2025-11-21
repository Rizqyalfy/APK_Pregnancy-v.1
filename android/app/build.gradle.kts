plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_pregnancy_care"
    compileSdk = 35 // Update ke versi yang lebih tinggi
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.my_pregnancy_care"
        minSdk = 21 // Pastikan minSdk 21 atau lebih tinggi
        targetSdk = 35 // Update targetSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Tambahkan untuk Android 12+ (API 31+)
        buildConfigField("String", "FLUTTER_NOTIFICATION_CHANNEL", "\"pregnancy_care_channel\"")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }

    // Tambahkan untuk Android 13+ permissions
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Tambahkan dependencies untuk notification dan image picker jika diperlukan
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
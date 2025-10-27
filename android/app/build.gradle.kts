plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    
    // Aplicamos el plugin de Google Services aquí.
    id("com.google.gms.google-services") // <-- ¡NUEVO!
}

android {
    namespace = "com.masai.futbol_pro" // <-- UNIFICADO
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Actualizado para apuntar a Java 21 (LTS)
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        // JVM target para Kotlin compilado a bytecode Java 21
        jvmTarget = "21"
    }

    defaultConfig {
        // CORREGIDO: Usamos el mismo nombre que el namespace para evitar conflictos de Clase No Encontrada.
        applicationId = "com.masai.futbol_pro" // <-- UNIFICADO
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ==========================================================
// ¡NUEVO! Sección de dependencias con Firebase BoM y Messaging
// ==========================================================
dependencies {
    // Importamos el Firebase Bill of Materials (BoM)
    implementation(platform("com.google.firebase:firebase-bom:33.1.0")) // Verifica la versión más reciente
    
    // Necesitamos el SDK de Firebase Cloud Messaging para las notificaciones
    implementation("com.google.firebase:firebase-messaging-ktx")
}

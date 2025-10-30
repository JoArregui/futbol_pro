plugins {
    id("com.android.application")
    id("kotlin-android")
    // El Plugin de Flutter debe aplicarse después de los plugins de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
    
    // Aplicamos el plugin de Google Services aquí.
    id("com.google.gms.google-services")
}

android {
    namespace = "com.masai.futbol_pro" // <-- ¡VERIFICA TU NAMESPACE!
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Habilitar el desugaring para compatibilidad (¡CORRECCIÓN CLAVE 1!)
        isCoreLibraryDesugaringEnabled = true 
        
        // Apuntamos a Java 21 (LTS)
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        // JVM target para Kotlin compilado a bytecode Java 21
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "com.masai.futbol_pro" // <-- Debe coincidir con el namespace
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ==========================================================
// Sección de dependencias corregida
// ==========================================================
dependencies {
    // 1. Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
   
    // 2. Firebase Messaging
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // 3. Desugaring - VERSIÓN ACTUALIZADA
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
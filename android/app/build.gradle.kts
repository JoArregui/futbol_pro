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
        
        // Apuntamos a Java 17 para evitar errores de compilación por compatibilidad del JDK
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // JVM target para Kotlin compilado a bytecode Java 17
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.masai.futbol_pro" // <-- Debe coincidir con el namespace
        minSdk = 23 // local_auth + notificaciones lo exigen
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Firma release vía android/key.properties (no commitear).
    // Si no existe, se usa debug solo para desarrollo local.
    val keyPropsFile = rootProject.file("key.properties")
    val keyProps = java.util.Properties()
    if (keyPropsFile.exists()) keyProps.load(java.io.FileInputStream(keyPropsFile))
    signingConfigs {
        create("release") {
            if (keyPropsFile.exists()) {
                storeFile = file(keyProps["storeFile"] as String)
                storePassword = keyProps["storePassword"] as String
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (keyPropsFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Solo dev local. CI/prod debe proveer key.properties.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

// ==========================================================
// Sección de dependencias CORREGIDA
// ==========================================================
dependencies {
    // 1. Desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // 2. ¡IMPORTANTE! Comentamos la BoM para evitar conflictos de resolución.
    // implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    
    // 3. Firebase Messaging - AÑADIMOS LA VERSIÓN EXPLÍCITAMENTE
    implementation("com.google.firebase:firebase-messaging-ktx:24.0.0") 
}
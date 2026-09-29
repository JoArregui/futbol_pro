// Top-level build file
plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Inyección de namespace para plugins antiguos (se ejecuta antes de evaluar las dependencias)
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExtension != null && androidExtension.namespace == null) {
            androidExtension.namespace = project.group.toString().ifEmpty {
                "com.example.${project.name.replace("-", "_")}"
            }
        }
    }

    // Evaluación de dependencias
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
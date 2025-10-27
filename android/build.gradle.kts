// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    // RESOLVIENDO CONFLICTO: Unificamos a la versión 4.3.15, ya que una dependencia de Firebase 
    // antigua la está cargando en el classpath.
    id("com.google.gms.google-services") version "4.3.15" apply false // <-- ¡VERSIÓN UNIFICADA!
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

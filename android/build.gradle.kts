// Plugin google-services dimuat dari repo Maven Google (google()), BUKAN
// dari Gradle Plugin Portal: marker artifact-nya tidak ter-resolve lewat
// portal di lingkungan ini (9 Nov 2026: portal mengarah ke Maven Central
// dan mengembalikan 404 untuk versi 4.4.2), sementara artifact-nya sendiri
// tersedia di maven.google.com. Modul app memakai plugin ini tanpa versi
// (lihat android/app/build.gradle.kts).
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
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

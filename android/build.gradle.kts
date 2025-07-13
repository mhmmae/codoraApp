plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Suppress Java 8 warnings for all subprojects
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:-deprecation"))
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Apply compiler settings to all subprojects
    afterEvaluate {
        tasks.withType<JavaCompile> {
            options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:-deprecation"))
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

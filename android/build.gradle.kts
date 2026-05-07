allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") } // TikTok Events SDK
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
// AGP 8+ requires every Android module to declare a namespace. Some legacy
// Flutter plugins (e.g. flutter_native_timezone_updated_gradle) still rely on
// the deprecated `package` manifest attribute and break the build. This
// patches them transparently by injecting a namespace derived from the
// historical package id when missing. Must be registered BEFORE the
// `evaluationDependsOn(":app")` hook below, otherwise Gradle has already
// evaluated the project by the time `afterEvaluate` is wired.
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (androidExt != null && androidExt.namespace == null) {
                val manifest = file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val text = manifest.readText()
                    val match = Regex("""package="([^"]+)"""").find(text)
                    if (match != null) {
                        androidExt.namespace = match.groupValues[1]
                    }
                }
            }
        }
        // Align Kotlin/Java target on every subproject. AGP 8 rejects mixed
        // targets (e.g. Java 17 vs Kotlin 11) with "Inconsistent JVM-target
        // compatibility". Recent Firebase Android libs require 17, so we pin
        // every module on 17.
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
        // Some legacy plugins set `java { sourceCompatibility = VERSION_1_8 }`
        // via the Java extension, which overrides plain JavaCompile task
        // settings. Rewrite it directly when present.
        extensions.findByType<org.gradle.api.plugins.JavaPluginExtension>()?.apply {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
        // And also force the Android extension's compileOptions when it exists
        // (some Flutter plugins still hard-code 1.8 there).
        (project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension)?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

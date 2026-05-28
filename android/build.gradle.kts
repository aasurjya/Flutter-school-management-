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

// Pin Kotlin language/api version to 1.8 across every subproject (including
// transitive Flutter plugins) so plugins still targeting the now-unsupported
// 1.6 (e.g. posthog_flutter ≤4.x) compile under the current Kotlin Gradle
// pipeline. Cheaper + safer than bumping every plugin's major version.
// configureEach is lazy by design — no afterEvaluate needed (and indeed an
// afterEvaluate here conflicts with evaluationDependsOn(":app") above).
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(
                org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
            apiVersion.set(
                org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

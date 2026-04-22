allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    // Some third-party Android modules still compile with source/target 8.
    // Suppress noisy lint warnings from third-party Java sources during builds.
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(
            listOf(
                "-Xlint:-options",
                "-Xlint:-unchecked",
            ),
        )
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

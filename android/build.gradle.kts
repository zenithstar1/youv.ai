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

// Do NOT use evaluationDependsOn(":app") here.
// It forces plugin projects (firebase_auth, etc.) to evaluate before their
// Android plugin is applied, which causes:
//   Configuration with name 'implementation' not found
//   java.lang.NullPointerException

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

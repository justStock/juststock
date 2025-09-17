import java.io.File
import java.util.Properties
import org.gradle.api.GradleException
import org.gradle.api.initialization.resolve.RepositoriesMode

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    val flutterSdkPath = run {
        val localProperties = File(settingsDir, "local.properties")
        if (localProperties.exists()) {
            Properties().apply {
                localProperties.inputStream().use { load(it) }
            }.getProperty("flutter.sdk")
        } else {
            System.getenv("FLUTTER_HOME")
        }
    }

    val resolvedFlutterSdkPath = flutterSdkPath ?: throw GradleException("Flutter SDK not found. Define flutter.sdk in local.properties or set FLUTTER_HOME.")

    includeBuild("/packages/flutter_tools/gradle")

    plugins {
        id("dev.flutter.flutter-plugin-loader") version "1.0.0"
        id("com.android.application") version "8.6.0"
        id("com.android.library") version "8.6.0"
        id("org.jetbrains.kotlin.android") version "2.0.21"
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

include(":app")
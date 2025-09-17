import java.util.Properties
import java.io.FileInputStream

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    val flutterSdkPath: String? = run {
        val f = File(settingsDir, "local.properties")
        if (f.exists()) {
            val p = Properties().apply { load(FileInputStream(f)) }
            p.getProperty("flutter.sdk")
        } else {
            System.getenv("FLUTTER_HOME")
        }
    }

    check(flutterSdkPath != null) {
        "Flutter SDK not found. Define flutter.sdk in local.properties or set FLUTTER_HOME."
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

  plugins {
    id("com.android.application") version "8.6.0"
    id("com.android.library") version "8.6.0"
    id("org.jetbrains.kotlin.android") version "2.0.21"
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
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

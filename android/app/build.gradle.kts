plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.homy.codora"
    compileSdk = 35
    ndkVersion = "29.0.13113456"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
    tasks.register("wrapper", Wrapper::class) {
        gradleVersion = "8.13"
    }

    tasks.register("prepareKotlinBuildScriptModel")
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:unchecked", "-Xlint:deprecation"))
    }



    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.homy.codora"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 27
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
    implementation("com.facebook.android:facebook-android-sdk:18.0.2")
    implementation("com.facebook.android:facebook-login:latest.release")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    
    implementation("com.google.android.gms:play-services-auth:21.3.0")
//    implementation("androidx.window:window:1.3.0")
//    implementation("androidx.window:window-java:1.3.0")
}

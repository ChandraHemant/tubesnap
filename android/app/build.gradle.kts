plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.itechqu.tube_snap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.itechqu.tube_snap"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (project.hasProperty("MYAPP_RELEASE_STORE_FILE")) {
                storeFile = file(project.property("MYAPP_RELEASE_STORE_FILE") as String)
                storePassword = project.property("MYAPP_RELEASE_STORE_PASSWORD") as String
                keyAlias = project.property("MYAPP_RELEASE_KEY_ALIAS") as String
                keyPassword = project.property("MYAPP_RELEASE_KEY_PASSWORD") as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    packaging {
        jniLibs {
            useLegacyPackaging = true
            pickFirsts += "**/libc++_shared.so"
            pickFirsts += "lib/**/libc++_shared.so"
            keepDebugSymbols += "**/libpython.zip.so"
            keepDebugSymbols += "**/libpython.*.so"
        }
    }
}

dependencies {
    implementation("io.github.junkfood02.youtubedl-android:library:0.18.1")
    // FFmpeg companion - provides libffmpeg.so so yt-dlp can merge video+audio streams.
    // Without this the APK ships NO libffmpeg.so and every mux-requiring download fails
    // with "ffmpeg-location ... does not exist".
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")
}

flutter {
    source = "../.."
}


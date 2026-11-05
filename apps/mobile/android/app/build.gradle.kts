plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun requiredEnv(name: String): String =
    System.getenv(name) ?: error("Falta $name: va junto con ANDROID_KEYSTORE_PATH")

android {
    namespace = "pe.cuycash.cuycash"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "pe.cuycash.cuycash"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // CI firma con la clave propia (secretos en docs/despliegue.md): todo APK
    // publicado debe llevar la misma, o no actualiza al ya instalado. Sin esas
    // variables, un release local usa la de depuración, que es de cada máquina.
    val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    if (keystorePath != null) {
        signingConfigs.create("release") {
            storeFile = file(keystorePath)
            storePassword = requiredEnv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = requiredEnv("ANDROID_KEY_ALIAS")
            keyPassword = requiredEnv("ANDROID_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName(if (keystorePath != null) "release" else "debug")
        }
    }

    // Cada flavor se instala aparte (applicationIdSuffix) y se distingue en el
    // teléfono por su nombre (`app_name`, que usa el AndroidManifest) y su ícono
    // (`src/<flavor>/res`, ver flutter_launcher_icons-<flavor>.yaml). Lo distinto
    // va PRIMERO en el nombre: el lanzador recorta los largos.
    flavorDimensions += "env"
    productFlavors {
        create("mock") {
            dimension = "env"
            applicationIdSuffix = ".mock"
            resValue("string", "app_name", "Mock · CuyCash")
        }
        create("local") {
            dimension = "env"
            applicationIdSuffix = ".local"
            resValue("string", "app_name", "Local · CuyCash")
        }
        create("production") {
            dimension = "env"
            resValue("string", "app_name", "CuyCash")
        }
    }
}

flutter {
    source = "../.."
}

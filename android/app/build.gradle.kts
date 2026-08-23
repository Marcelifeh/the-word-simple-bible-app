import java.io.FileInputStream
import java.net.URI
import java.nio.charset.StandardCharsets
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

fun decodedDartDefines(): Map<String, String> =
    providers.gradleProperty("dart-defines").orNull
        ?.split(',')
        ?.filter { it.isNotBlank() }
        ?.associate { encoded ->
            val decoded = String(
                Base64.getDecoder().decode(encoded),
                StandardCharsets.UTF_8,
            )
            val separator = decoded.indexOf('=')
            if (separator <= 0) {
                throw GradleException("Malformed --dart-define in release build.")
            }
            decoded.substring(0, separator) to decoded.substring(separator + 1)
        }
        ?: emptyMap()

fun requireSecureReleaseUrl(name: String, value: String?, required: Boolean) {
    val trimmed = value?.trim().orEmpty()
    if (trimmed.isEmpty()) {
        if (required) throw GradleException("Release build requires --dart-define=$name=<HTTPS URL>.")
        return
    }
    val uri = try {
        URI(trimmed)
    } catch (_: Exception) {
        throw GradleException("$name must be a valid absolute HTTPS URL.")
    }
    val host = uri.host?.lowercase().orEmpty()
    val blockedHosts = setOf("localhost", "127.0.0.1", "::1", "10.0.2.2")
    if (uri.scheme?.lowercase() != "https" || host.isEmpty() || host in blockedHosts) {
        throw GradleException("$name must use HTTPS and must not use a local or loopback host.")
    }
}

if (releaseTaskRequested) {
    val defines = decodedDartDefines()
    requireSecureReleaseUrl("SERMON_API_URL", defines["SERMON_API_URL"], required = true)
    requireSecureReleaseUrl("COMMENTARY_API_URL", defines["COMMENTARY_API_URL"], required = false)
    requireSecureReleaseUrl("AUDIO_API_URL", defines["AUDIO_API_URL"], required = false)
    requireSecureReleaseUrl("BIBLE_API_URL", defines["BIBLE_API_URL"], required = false)
    if (defines["SERMON_TRANSCRIPTION_ENABLED"]?.lowercase() != "false") {
        throw GradleException(
            "Release build requires --dart-define=SERMON_TRANSCRIPTION_ENABLED=false.",
        )
    }
}
if (releaseTaskRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Release signing is not configured. Create android/key.properties " +
            "from android/key.properties.example before building a release.",
    )
}

fun requiredSigningProperty(name: String): String =
    keystoreProperties.getProperty(name)
        ?: throw GradleException("Missing '$name' in android/key.properties")

android {
    namespace = "org.thewordapp.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "org.thewordapp.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = requiredSigningProperty("keyAlias")
                keyPassword = requiredSigningProperty("keyPassword")
                storeFile = file(requiredSigningProperty("storeFile"))
                storePassword = requiredSigningProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

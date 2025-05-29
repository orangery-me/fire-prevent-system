# 🔥 Smart Alert App

Ứng dụng Flutter theo dõi cảm biến, gửi cảnh báo và điều khiển động cơ khi phát hiện cháy hoặc rò rỉ gas.

## Tính năng chính

- Cảnh báo cháy và rò rỉ gas
- Gửi thông báo đẩy cục bộ (local notification)
- Dễ dàng mở rộng và tích hợp với hệ thống IoT

---

## Yêu cầu

- Flutter SDK ≥ 3.x
- Thiết bị Android (API 21+)
  (_Android 13+ yêu cầu quyền thông báo_)
- Đã cài đặt `flutter_local_notifications`

---

## Cài đặt

```bash
git clone https://github.com/orangery-me/fire-prevent-system.git
flutter pub get
```

## Cài thư viện Flutter

```
  flutter:
    sdk: flutter
  flutter_local_notifications: ^17.0.0
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  permission_handler: ^11.3.0
```

## Cài plugin Android (build.gradle)

`android/build.gradle`

```
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
    id("com.google.gms.google-services")   // Firebase plugin
}
```

`android/app/build.gradle`

```android {
    namespace = "com.example.fire_prevent_system"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.fire_prevent_system"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.google.firebase:firebase-firestore-ktx")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

## Chạy ứng dụng

`flutter run`

## Cho phép gửi thông báo

**Android (13+)**

Thêm quyền vào `android/app/src/main/AndroidManifest.xml`:

```
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

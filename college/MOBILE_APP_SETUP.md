# KSRCE ERP - Mobile App (iOS/Android) Setup Guide

## Overview
This document provides step-by-step instructions to build and deploy the KSRCE ERP Flutter app for iOS and Android platforms.

---

## Prerequisites
- Flutter SDK 3.19+ installed
- Xcode 14+ (for iOS development)
- Android Studio 2023+ (for Android development)
- CocoaPods installed (for iOS dependencies)
- Apple Developer Account (for iOS deployment)
- Google Play Developer Account (for Android deployment)

---

## Project Structure
```
college/
├── android/
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── AndroidManifest.xml
│   │   │   │   └── kotlin/com/ksrce/erp/MainActivity.kt
│   │   │   └── debug/, release/
│   │   ├── build.gradle
│   │   └── google-services.json
│   ├── build.gradle
│   └── gradle.properties
├── ios/
│   ├── Runner.xcworkspace
│   ├── Runner/
│   │   ├── Info.plist
│   │   ├── GeneratedPluginRegistrant.swift
│   │   └── GoogleService-Info.plist
│   ├── Podfile
│   └── Podfile.lock
├── pubspec.yaml
└── lib/
```

---

## Phase 1: Android Configuration

### 1.1 Update AndroidManifest.xml

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ksrce.erp">

    <!-- Required Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Application declaration -->
    <application
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:requestLegacyExternalStorage="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Specifies an Android theme to apply to this Activity -->
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Add Firebase configuration -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

    </application>
</manifest>
```

### 1.2 Update build.gradle

**File**: `android/app/build.gradle`

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

android {
    namespace = "com.ksrce.erp"
    compileSdk = 34
    ndkVersion = "26.0.10792818"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.ksrce.erp"
        minSdkVersion = 21
        targetSdkVersion = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.release
            minifyEnabled = true
            shrinkResources = true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            debuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation "com.google.android.material:material:1.12.0"
    implementation "androidx.multidex:multidex:2.0.1"
    implementation platform('com.google.firebase:firebase-bom:33.0.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-database'
}
```

### 1.3 Add google-services.json

Download from Firebase Console and place at: `android/app/google-services.json`

### 1.4 Create Release Signing Key

```bash
# Generate keystore for release builds
keytool -genkey -v -keystore ~/ksrce_erp_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ksrce_key

# Reference in android/key.properties
storeFile=~/ksrce_erp_keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ksrce_key
```

---

## Phase 2: iOS Configuration

### 2.1 Update Info.plist

**File**: `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>KSRCE ERP</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    <key>NSCameraUsageDescription</key>
    <string>Camera access is needed to upload profile photos and document proofs</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Photo library access is needed to select profile photos and documents</string>
    <key>NSPhotoLibraryAddOnlyUsageDescription</key>
    <string>Permission needed to save photos</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>Local network access is needed for optimal performance</string>
</dict>
</plist>
```

### 2.2 Update Podfile

**File**: `ios/Podfile`

```ruby
platform :ios, '11.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join(
    File.dirname(__FILE__), 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
      target.build_configurations.each do |config|
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
          '$(inherited)',
          'PERMISSION_CAMERA=1',
          'PERMISSION_PHOTOS=1',
        ]
      end
    end
  end
end
```

### 2.3 Add GoogleService-Info.plist

Download from Firebase Console and place at: `ios/Runner/GoogleService-Info.plist`

### 2.4 Update iOS Build Settings

```
Runner -> Build Settings:
- Minimum Deployment Target: 11.0
- Product Bundle Identifier: com.ksrce.erp
- Team ID: YOUR_APPLE_TEAM_ID
- Development Team: Your Name
```

---

## Phase 3: Build & Test

### 3.1 Android Build

```bash
# Clean flutter build
flutter clean

# Get dependencies
flutter pub get

# Build APK for testing
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# App Bundle: build/app/outputs/bundle/release/app-release.aab
```

### 3.2 iOS Build

```bash
# Clean flutter build
flutter clean

# Get dependencies
flutter pub get

# Install pod dependencies
cd ios && pod install --repo-update && cd ..

# Build for release (creates .ipa)
flutter build ios --release

# Build for testing
flutter build ios --release
open ios/Runner.xcworkspace

# In Xcode:
# Product > Archive > Validate > Distribute to App Store
```

### 3.3 Testing on Devices

```bash
# Run on connected Android device
flutter run --release

# Run on iOS simulator
flutter run -t lib/main.dart --release

# Install APK on Android device
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Phase 4: Deployment

### 4.1 Google Play Store Deployment

1. Create app listing in Google Play Console
2. Upload App Bundle (`.aab`)
3. Add app description, screenshots, graphics
4. Set pricing and distribution
5. Get release approval (can take 24-48 hours)

**Steps**:
```bash
# In Google Play Console:
1. All apps > Create app
2. App name: "KSRCE ERP"
3. Category: "Education"
4. Content rating: Complete questionnaire
5. Upload build: app-release.aab
6. Create release: Set version name/code
7. Add content: Screenshots, descriptions
8. Review & rollout
```

### 4.2 Apple App Store Deployment

1. Create app in App Store Connect
2. Configure app rights and ages
3. Upload build via Xcode or Transporter
4. Add metadata and screenshots
5. Submit for review

**Steps**:
```bash
# In Xcode:
1. Product > Archive
2. Archives organizer > Validate App
3. Distribute App > App Store Connect
4. Follow prompts to upload

# Or use Transporter app from App Store
```

### 4.3 TestFlight (iOS Pre-Release)

```bash
# Build and upload for TestFlight
flutter build ios --release

# In Xcode:
1. Product > Archive
2. Archives organizer > Upload to App Store
3. Select TestFlight
4. Add internal/external testers
5. TestFlight link shared with testers
```

### 4.4 Firebase App Distribution (Android Pre-Release)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Upload APK to Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --testers "test1@example.com,test2@example.com"
```

---

## Phase 5: Post-Deployment Maintenance

### 5.1 Monitoring

- Firebase Analytics tracking
- Crash reporting via Sentry/Firebase Crashlytics
- User engagement metrics
- Performance monitoring

### 5.2 Updates & Versioning

```yaml
# Update version in pubspec.yaml
version: 1.0.1+2  # version+buildNumber

# Rebuild and upload
flutter build appbundle --release
flutter build ios --release
```

### 5.3 Push Notifications Setup

```dart
// In main.dart
import 'package:firebase_messaging/firebase_messaging.dart';

FirebaseMessaging messaging = FirebaseMessaging.instance;

// Request permission (iOS only)
await messaging.requestPermission();

// Get FCM token
String? token = await messaging.getToken();

// Handle foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Display notification to user
});

// Handle background messages
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## API Keys & Secrets

**Create `.env.production` file** (DO NOT COMMIT):
```
FIREBASE_APP_ID=YOUR_APP_ID
FIREBASE_API_KEY=YOUR_API_KEY
FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
GOOGLE_PLAY_SERVICE_ACCOUNT=path/to/service-account.json
APP_STORE_KEY_ID=YOUR_KEY_ID
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| iOS build fails | `cd ios && pod deintegrate && pod install` |
| Android build fails | `flutter clean && flutter pub get` |
| Firebase config not found | Download JSON from Firebase Console |
| App crashes on startup | Check logs: `flutter logs` |
| Slow iOS build | Enable Bitcode: set to NO in Xcode |

---

## Success Checklist

- [ ] Dependencies updated in pubspec.yaml
- [ ] AndroidManifest.xml configured
- [ ] Info.plist configured
- [ ] Firebase credentials added
- [ ] Release signing configured
- [ ] APK builds successfully
- [ ] IPA builds successfully
- [ ] App tested on real device
- [ ] Google Play listing created
- [ ] App Store listing created
- [ ] Submissions approved
- [ ] Analytics & Crashlytics working
- [ ] Push notifications enabled

---

## Resources

- Flutter Docs: https://flutter.dev/docs
- Firebase Setup: https://firebase.google.com/docs/flutter/setup
- Play Store Guide: https://support.google.com/googleplay/android-developer
- App Store Guide: https://help.apple.com/app-store-connect/
- TestFlight Guide: https://developer.apple.com/testflight/

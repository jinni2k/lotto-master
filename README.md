# lotto_master

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release Guide

### 1. Keystore Setup
Create `android/key.properties` file based on `android/key.properties.example`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

### 2. Build for Production
To build the Android App Bundle (AAB):
```bash
flutter build appbundle --release
```

### 3. Play Store Release
The `build.yml` workflow automatically builds the AAB when a release is published on GitHub.
1. Draft a new release on GitHub.
2. Publish the release.
3. Download the AAB artifact from Actions.
4. Upload to Play Console.

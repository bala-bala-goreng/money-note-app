# Publish Checklist

Before submitting to Google Play or App Store:

## 1. Package / Bundle ID

- **Done**: Set to `com.perutkentang.spendly` (Android, iOS, macOS).

## 2. Signing

### Android (Release)

- Copy `android/key.properties.example` to `android/key.properties`.
- Generate a keystore:  
  `keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- Fill in `key.properties` with storePassword, keyPassword, keyAlias, storeFile path.
- Build: `flutter build appbundle --release`

### iOS

- In Xcode, select the Runner target → Signing & Capabilities. Set your Team and provisioning profile.
- Archive and upload from Xcode (Product → Archive).

## 3. App Store Assets

- **Screenshots**: Take screenshots for required device sizes (Phone, Tablet if supported).
- **App icon**: Already configured via `flutter_launcher_icons`. Run `dart run flutter_launcher_icons` if you change the logo.
- **Store listing**: Title, short description, full description, privacy policy URL (if required).

## 4. Privacy

- **Android**: No special privacy form needed if you don’t collect personal data. The app uses local storage only.
- **iOS**: Add a Privacy Policy URL in App Store Connect if your app accesses user data. Consider a simple privacy policy stating: "Data is stored only on your device. We do not collect or transmit personal data."

## 5. Build Commands

```bash
# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# Android APK
flutter build apk --release

# iOS (then archive in Xcode)
flutter build ios --release
```

## 6. Pre-submission Check

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Test on a real device (debug and release)
- [ ] Version in `pubspec.yaml` is updated (e.g. 1.0.0+1 → 1.0.1+2 for a new release)

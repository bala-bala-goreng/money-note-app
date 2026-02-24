# Money Note App

A simple app to track your income and expenses. Everything is stored on your device (SQLite). No account, no cloud—just you and your numbers.

**What it does:**
- Dashboard with three boxes: total expenses, balance, total income
- Two tabs below: one for expense list, one for income list
- Add transactions with a category, description, and amount
- Manage categories (add, edit, pick an icon). Expenses show in red, income in green

---

## What you need before running

- **Flutter** (3.11 or newer). If you don’t have it: [flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- **Android**: Android Studio (for the SDK and emulator) or at least the Android SDK + a device/emulator
- **iOS**: Xcode (from the Mac App Store) if you want to run on simulator or device
- **macOS desktop**: Xcode installed and set up if you want to run the app as a Mac app

Check that everything is OK:

```bash
flutter doctor -v
```

Fix whatever it complains about (e.g. “Android SDK not found” → install Android Studio and set it up; “Xcode not configured” → install Xcode and run the first-launch steps it suggests).

---

## Project structure

Roughly how the code is organised:

```
money-note-app/
├── lib/
│   ├── main.dart                 → App entry, sets up Provider and theme
│   ├── models/
│   │   ├── category.dart         → Category (name, icon, income vs expense)
│   │   └── transaction.dart     → Single transaction (amount, description, category, date)
│   ├── database/
│   │   └── database_helper.dart  → SQLite: create DB, tables, read/write categories & transactions
│   ├── providers/
│   │   └── money_note_provider.dart  → Loads/saves data, notifies UI when something changes
│   ├── screens/
│   │   ├── dashboard_screen.dart      → Main screen: 3 boxes + tabs + lists
│   │   ├── add_transaction_screen.dart → Form to add income/expense
│   │   └── category_management_screen.dart → List and add/edit categories
│   ├── widgets/
│   │   ├── summary_box.dart      → One of the three dashboard cards
│   │   ├── transaction_list.dart → List of transactions for a tab
│   │   └── transaction_list_item.dart → One row (category, description, amount)
│   └── utils/
│       └── category_icons.dart   → Maps icon names to Material icons
├── android/    → Android app config and build files
├── ios/        → iOS app config and build files
├── macos/      → macOS desktop app config (if you added that platform)
├── test/
│   └── widget_test.dart
└── pubspec.yaml   → Dependencies (Flutter, sqflite, provider, intl, etc.)
```

**Dependencies (from pubspec):**
- `sqflite` + `path` – local SQLite database
- `provider` – state management so the UI updates when data changes
- `intl` – formatting money and dates

---

## How to run the project

### 1. Get the code and install dependencies

```bash
cd money-note-app
flutter pub get
```

### 2. Pick a device

**Option A – Android emulator**

- Open Android Studio → More Actions → Virtual Device Manager
- Create a device (e.g. Pixel, API 34 or 36) and download a system image if it asks
- Start the emulator (play button next to the device)

**Option B – Real Android phone**

- Turn on “Developer options” and “USB debugging” on the phone
- Plug it in with USB
- Run `flutter devices` and you should see your phone

**Option C – iOS simulator (Mac only)**

- Install Xcode from the App Store
- Run: `open -a Simulator`
- Run `flutter devices` and you should see the simulator

**Option D – Chrome (web)**

- Install Chrome if you don’t have it
- Run: `flutter run -d chrome`

### 3. Run the app

```bash
flutter run
```

If you have more than one device, pick one:

```bash
flutter devices
flutter run -d <device_id>
```

Example: `flutter run -d emulator-5554` or `flutter run -d chrome`.

First run on Android can take a few minutes (Gradle, NDK, etc.). Later runs are faster.

---

## How to debug

- **Breakpoints:** Open any `.dart` file (e.g. in VS Code or Android Studio), click in the gutter next to a line number to set a breakpoint. Run with **Debug** (e.g. “Run and Debug” in VS Code, or the bug icon in Android Studio), not “Run”. Execution will stop at the breakpoint so you can inspect variables and step through.
- **Print / logs:** Use `debugPrint('something')` or `print()` in Dart. Output shows in the terminal where you ran `flutter run`, or in the Debug Console in your editor.
- **Flutter DevTools:** When the app is running, the terminal often prints a link to DevTools. Open it in the browser to inspect widgets, performance, and logs.
- **Hot reload:** While `flutter run` is active, press `r` in the terminal to hot reload (keeps state). Press `R` for hot restart (full restart). Saves time when you’re tweaking UI or logic.

---

## How to build (APK, app bundle, etc.)

**Debug APK (quick test build, not for store):**

```bash
flutter build apk --debug
```

The APK is under `build/app/outputs/flutter-apk/app-debug.apk`. Install it on a device with “Install from unknown sources” allowed, or drag it onto an emulator.

**Release APK (for sharing or store):**

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. You may need to sign the app for the Play Store; that’s done in Android Studio (Generate signed bundle/APK) or with keytool + gradle config.

**Android App Bundle (recommended for Play Store):**

```bash
flutter build appbundle --release
```

**iOS (Mac + Xcode only):**

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode and archive/upload from there.

**macOS desktop:**

```bash
flutter build macos --release
```

---

## Tests

```bash
flutter test
```

Runs the tests in the `test/` folder (e.g. `widget_test.dart`).

---

## Quick reference

| I want to…              | Command / step |
|-------------------------|----------------|
| Install packages        | `flutter pub get` |
| See devices             | `flutter devices` |
| Run app                 | `flutter run` |
| Run on specific device  | `flutter run -d <id>` |
| Debug build (APK)       | `flutter build apk --debug` |
| Release build (APK)     | `flutter build apk --release` |
| Run tests               | `flutter test` |
| Check environment       | `flutter doctor -v` |

If something doesn’t work, run `flutter doctor -v` and fix the issues it reports. For “no devices”, start an emulator or connect a phone and enable USB debugging.

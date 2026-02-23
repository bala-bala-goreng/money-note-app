# Money Note

A simple Flutter app to track income and expenses. Built with best practices for iOS and Android, with inline comments to help you learn.

## Features

- **Dashboard** – 3 summary boxes (Expenses, Balance, Income) + tabbed list of transactions
- **Add transactions** – Record income or expense with category, description, and amount
- **Category management** – Add or edit categories with predefined icons
- **Local storage** – SQLite (via `sqflite`) keeps data on device
- **Color coding** – Red for expenses, green for income (amounts only)

## Setup

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (3.11+)
- Android Studio / Xcode (for mobile)

### Installation

1. **Clone or navigate to the project:**
   ```bash
   cd money-note-app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Check your environment:**
   ```bash
   flutter doctor -v
   ```
   Ensure Android toolchain and/or Xcode are OK for your target platform.

## Run the Project

```bash
# Run on connected device or emulator
flutter run

# Run on a specific device
flutter devices
flutter run -d <device_id>

# Run on Chrome (web)
flutter run -d chrome
```

## Project Structure (for Learning)

```
lib/
├── main.dart                 # App entry, Provider setup
├── models/
│   ├── category.dart         # Category model (id, name, icon, type)
│   └── transaction.dart      # Transaction model
├── database/
│   └── database_helper.dart  # SQLite CRUD, table creation
├── providers/
│   └── money_note_provider.dart  # State management, loads/saves data
├── screens/
│   ├── dashboard_screen.dart     # Main page: boxes + tabs
│   ├── add_transaction_screen.dart
│   └── category_management_screen.dart
├── widgets/
│   ├── summary_box.dart          # Reusable summary card
│   ├── transaction_list.dart
│   └── transaction_list_item.dart
└── utils/
    └── category_icons.dart       # Map icon names to Material Icons
```

## Tests

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --reporter expanded
```

## Tech Stack

| Package   | Purpose                          |
|----------|-----------------------------------|
| sqflite  | SQLite database                   |
| provider | State management                  |
| intl     | Currency/date formatting          |

## Screenshots (Concept)

- **Dashboard:** Top row = Expense | Balance | Income. Below = tabs for Expense/Income list.
- **Add Transaction:** Type (Income/Expense), Category, Description, Amount.
- **Categories:** List with edit, FAB to add. Icon picker in add/edit dialog.

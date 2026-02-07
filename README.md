# Road Ronin Finance

A personal expense tracker app with SMS integration for automatic transaction detection.

## Features

- 📱 **SMS Detection**: Automatically detects bank/UPI transaction SMS
- 🔔 **Smart Notifications**: Get notified when money is debited/credited
- 💰 **Multi-Bank Support**: Track HDFC, SBI, ICICI, Axis, and more
- 📊 **Daily Timeline**: View transactions grouped by day with passbook-style balance
- 📝 **Dues Management**: Track money to collect and give (Khata/Ledger)
- ✏️ **Full CRUD**: Edit/delete past transactions with automatic balance recalculation

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Android device (for SMS features)

### Installation

1. **Install Flutter** (if not already installed):
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Build APK for side-loading**:
   ```bash
   flutter build apk --release
   ```

### Permissions

Since this app is for personal use (side-loaded), you'll need to manually grant these permissions after installation:

1. Open Android Settings
2. Go to Apps → Road Ronin Finance → Permissions
3. Enable:
   - SMS (Read and Receive)
   - Notifications

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── database/
│   └── database_helper.dart     # SQLite operations
├── models/
│   ├── transaction_model.dart   # Transaction data model
│   ├── due_model.dart           # Dues data model
│   └── account_model.dart       # Bank account model
├── screens/
│   ├── home_screen.dart         # Dashboard & transaction list
│   ├── add_transaction_screen.dart
│   ├── dues_screen.dart
│   └── add_due_screen.dart
├── services/
│   ├── sms_service.dart         # SMS parsing & listening
│   └── notification_service.dart
└── widgets/
    ├── summary_card.dart
    ├── transaction_tile.dart
    └── due_tile.dart
```

## Usage

### Automatic SMS Tracking
1. Make a payment using GPay/PhonePe/etc.
2. You'll receive a notification: "₹500 Spent - Tap to add details"
3. Tap the notification to confirm transaction details
4. Add description, category, and save

### Manual Entry
1. Tap the + button on the home screen
2. Select Expense or Income
3. Enter amount, receiver, category, description
4. Save

### Dues Management
1. Go to Dues tab
2. Tap "Add Due"
3. Select "To Collect" or "To Give"
4. Enter person name and amount
5. When payment is made, the app will suggest settling the due automatically

## License

Personal use only.
# Finance-Tracker-App

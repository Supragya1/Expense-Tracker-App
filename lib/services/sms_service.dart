import 'package:telephony/telephony.dart';
import 'notification_service.dart';

/// SMS Parser Service - Extracts transaction data from bank SMS
class SmsService {
  static final SmsService instance = SmsService._init();
  final Telephony telephony = Telephony.instance;

  SmsService._init();

  /// Initialize SMS listener (foreground + background)
  Future<void> init() async {
    final permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted == true) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          // Foreground handler
          _processSms(message);
        },
        onBackgroundMessage: onBackgroundMessage,
      );
    }
  }

  /// Process incoming SMS
  void _processSms(SmsMessage message) {
    final body = message.body ?? "";
    final sender = message.address ?? "";

    // Filter: Only process bank/financial SMS
    if (!_isBankSms(sender, body)) return;

    // Extract data
    final amount = _extractAmount(body);
    if (amount == null) return;

    final type = _extractType(body);
    final bankName = _getBankName(sender);
    final receiverName = _extractReceiverName(body, type);
    final balance = _extractBalance(body);

    // Create payload: "amount|bank|type|receiver|balance|timestamp"
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload =
        "$amount|$bankName|$type|$receiverName|${balance ?? 0}|$timestamp";

    // Show notification
    NotificationService.instance.showTransactionNotification(
      amount: amount,
      bankName: bankName,
      type: type,
      receiverName: receiverName,
      payload: payload,
    );
  }

  /// Check if SMS is from a bank/financial service
  bool _isBankSms(String sender, String body) {
    // Known bank sender patterns
    final bankPatterns = [
      'HDFC',
      'SBI',
      'ICICI',
      'AXIS',
      'KOTAK',
      'PNB',
      'BOB',
      'BOI',
      'CITI',
      'IDFC',
      'IDBI',
      'FEDERAL',
      'CANARA',
      'UNION',
      'INDIAN',
      'PAYTM',
      'GPAY',
      'PHONEPE',
      'AMAZONPAY',
      'BHIM',
    ];

    // Check sender ID
    final isBankSender = bankPatterns.any(
      (bank) => sender.toUpperCase().contains(bank),
    );

    // Check body for financial keywords
    final hasFinancialKeyword = body.toLowerCase().contains('debited') ||
        body.toLowerCase().contains('credited') ||
        body.toLowerCase().contains('spent') ||
        body.toLowerCase().contains('received') ||
        body.toLowerCase().contains('transferred');

    // Exclude OTPs
    final isNotOtp = !body.toUpperCase().contains('OTP') &&
        !body.toUpperCase().contains('ONE TIME PASSWORD');

    return isBankSender && hasFinancialKeyword && isNotOtp;
  }

  /// Extract amount from SMS
  double? _extractAmount(String body) {
    // Patterns: "Rs. 500", "INR 500.00", "Rs500", "₹ 500"
    final patterns = [
      RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'([\d,]+\.?\d*)\s*(?:Rs\.?|INR|₹)', caseSensitive: false),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  /// Determine if DEBIT or CREDIT
  String _extractType(String body) {
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('credited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('deposited')) {
      return 'CREDIT';
    }
    return 'DEBIT';
  }

  /// Map sender ID to bank name
  String _getBankName(String sender) {
    final senderUpper = sender.toUpperCase();

    final bankMappings = {
      'HDFC': 'HDFC',
      'SBI': 'SBI',
      'ICICI': 'ICICI',
      'AXIS': 'Axis',
      'KOTAK': 'Kotak',
      'PNB': 'PNB',
      'BOB': 'BOB',
      'IDFC': 'IDFC',
      'PAYTM': 'Paytm',
      'GPAY': 'GPay',
      'PHONEPE': 'PhonePe',
    };

    for (final entry in bankMappings.entries) {
      if (senderUpper.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Other';
  }

  /// Extract receiver/merchant name from SMS
  String _extractReceiverName(String body, String type) {
    // For CREDIT (income), look for "from"
    if (type == 'CREDIT') {
      final fromPattern = RegExp(
        r'(?:from|by)\s+([a-zA-Z0-9\s\.@-]+?)(?:\s+(?:on|via|ref|bal|a/c)|$)',
        caseSensitive: false,
      );
      final match = fromPattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Income';
      }
      return 'Income';
    }

    // For DEBIT (expense), look for "to" or "at"
    final patterns = [
      // "paid Rs 500 to Zomato"
      RegExp(
        r'(?:paid|sent|transferred)\s+(?:Rs\.?|INR|₹)?\s*[\d,\.]+\s+to\s+([a-zA-Z0-9\s\.@-]+?)(?:\s+(?:on|via|ref|bal)|$)',
        caseSensitive: false,
      ),
      // "debited Rs 500 at Starbucks"
      RegExp(
        r'(?:debited|spent)\s+(?:Rs\.?|INR|₹)?\s*[\d,\.]+\s+at\s+([a-zA-Z0-9\s\.@-]+?)(?:\s+(?:on|via|ref|bal)|$)',
        caseSensitive: false,
      ),
      // "to Merchant Name"
      RegExp(
        r'\bto\s+([a-zA-Z0-9\s\.@-]+?)(?:\s+(?:on|via|ref|bal|upi)|$)',
        caseSensitive: false,
      ),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'UPI Payment';
      }
    }

    return 'UPI Payment';
  }

  /// Extract available balance from SMS
  double? _extractBalance(String body) {
    // Patterns: "Bal Rs 5000", "Avail Bal: 5000.00", "Avl Bal INR 5000"
    final balanceRegex = RegExp(
      r'(?:Bal|Avail|Avl\.?)\s*(?:Bal)?\s*(?:Rs\.?|INR|:)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    final match = balanceRegex.firstMatch(body);
    if (match != null) {
      final balanceStr = match.group(1)?.replaceAll(',', '') ?? '';
      return double.tryParse(balanceStr);
    }
    return null;
  }
}

/// Top-level background message handler
/// MUST be a top-level function (not a class method)
@pragma('vm:entry-point')
void onBackgroundMessage(SmsMessage message) async {
  // Process in background
  final body = message.body ?? "";
  final sender = message.address ?? "";

  // Quick filter
  if (!_quickBankCheck(sender, body)) return;

  // Extract amount
  final amountMatch =
      RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)', caseSensitive: false)
          .firstMatch(body);
  if (amountMatch == null) return;

  final amount =
      double.tryParse(amountMatch.group(1)?.replaceAll(',', '') ?? '');
  if (amount == null) return;

  final type = body.toLowerCase().contains('credited') ? 'Income' : 'Expense';
  final bankName = _quickBankName(sender);

  // Show notification
  await NotificationService.instance.showTransactionNotification(
    amount: amount,
    bankName: bankName,
    type: type,
    receiverName: 'Transaction',
    payload:
        '$amount|$bankName|$type|Transaction|0|${DateTime.now().millisecondsSinceEpoch}',
  );
}

/// Quick bank check for background
bool _quickBankCheck(String sender, String body) {
  final hasBank =
      sender.toUpperCase().contains(RegExp(r'HDFC|SBI|ICICI|AXIS|PAYTM'));
  final hasMoney = body.toLowerCase().contains('debited') ||
      body.toLowerCase().contains('credited');
  return hasBank && hasMoney;
}

/// Quick bank name for background
String _quickBankName(String sender) {
  final s = sender.toUpperCase();
  if (s.contains('HDFC')) return 'HDFC';
  if (s.contains('SBI')) return 'SBI';
  if (s.contains('ICICI')) return 'ICICI';
  if (s.contains('AXIS')) return 'Axis';
  return 'Bank';
}

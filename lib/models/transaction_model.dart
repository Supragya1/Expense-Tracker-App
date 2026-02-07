/// Transaction Model - Represents a single financial transaction
/// with all details for passbook-style tracking
class TransactionModel {
  final int? id;
  final double amount;
  final String type; // "DEBIT" (Expense) or "CREDIT" (Income)
  final String bankName; // "HDFC", "SBI", "ICICI"
  final String paymentApp; // "GPay", "PhonePe", "BHIM", "Card", "NetBanking"
  final String receiverName; // "Zomato", "Rahul", "Electricity Bill"
  final String description; // User's custom note
  final DateTime timestamp;
  final String category; // "Food", "Travel", "Bills", etc.
  final double? balanceSnapshot; // Balance AFTER this transaction

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.bankName,
    this.paymentApp = "UPI",
    this.receiverName = "Unknown",
    this.description = "",
    required this.timestamp,
    this.category = "Uncategorized",
    this.balanceSnapshot,
  });

  /// Convert to Map for SQLite insert/update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'bank_name': bankName,
      'payment_app': paymentApp,
      'receiver_name': receiverName,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'category': category,
      'balance_snapshot': balanceSnapshot,
    };
  }

  /// Create from SQLite row
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      bankName: map['bank_name'] as String,
      paymentApp: map['payment_app'] as String? ?? "UPI",
      receiverName: map['receiver_name'] as String? ?? "Unknown",
      description: map['description'] as String? ?? "",
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      category: map['category'] as String? ?? "Uncategorized",
      balanceSnapshot: (map['balance_snapshot'] as num?)?.toDouble(),
    );
  }

  /// Create a copy with modified fields
  TransactionModel copyWith({
    int? id,
    double? amount,
    String? type,
    String? bankName,
    String? paymentApp,
    String? receiverName,
    String? description,
    DateTime? timestamp,
    String? category,
    double? balanceSnapshot,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      bankName: bankName ?? this.bankName,
      paymentApp: paymentApp ?? this.paymentApp,
      receiverName: receiverName ?? this.receiverName,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      balanceSnapshot: balanceSnapshot ?? this.balanceSnapshot,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, $type ₹$amount to $receiverName via $paymentApp/$bankName)';
  }
}

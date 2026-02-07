/// Account Model - Tracks bank account balances
class AccountModel {
  final String bankName; // Primary Key: "HDFC", "SBI", "ICICI"
  final double currentBalance;

  AccountModel({
    required this.bankName,
    required this.currentBalance,
  });

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'bank_name': bankName,
      'current_balance': currentBalance,
    };
  }

  /// Create from SQLite row
  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      bankName: map['bank_name'] as String,
      currentBalance: (map['current_balance'] as num).toDouble(),
    );
  }

  AccountModel copyWith({
    String? bankName,
    double? currentBalance,
  }) {
    return AccountModel(
      bankName: bankName ?? this.bankName,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  @override
  String toString() {
    return 'Account($bankName: ₹$currentBalance)';
  }
}

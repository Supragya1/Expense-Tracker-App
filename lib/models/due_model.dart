/// Due Model - Represents money to collect or give (Khata/Ledger)
class DueModel {
  final int? id;
  final String personName; // "Rahul (Freelancer)", "Client Oracle"
  final double amount;
  final String type; // "TO_COLLECT" (Receivable) or "TO_GIVE" (Payable)
  final String description; // "Logo Design Fee", "Project Advance"
  final DateTime? dueDate; // Expected date (optional)
  final String status; // "PENDING" or "CLEARED"
  final DateTime createdAt;

  DueModel({
    this.id,
    required this.personName,
    required this.amount,
    required this.type,
    this.description = "",
    this.dueDate,
    this.status = "PENDING",
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_name': personName,
      'amount': amount,
      'type': type,
      'description': description,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from SQLite row
  factory DueModel.fromMap(Map<String, dynamic> map) {
    return DueModel(
      id: map['id'] as int?,
      personName: map['person_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      description: map['description'] as String? ?? "",
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      status: map['status'] as String? ?? "PENDING",
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Create copy with modifications
  DueModel copyWith({
    int? id,
    String? personName,
    double? amount,
    String? type,
    String? description,
    DateTime? dueDate,
    String? status,
  }) {
    return DueModel(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  bool get isPending => status == "PENDING";
  bool get isToCollect => type == "TO_COLLECT";
  bool get isToGive => type == "TO_GIVE";

  @override
  String toString() {
    return 'Due($type: ₹$amount ${isToCollect ? "from" : "to"} $personName - $status)';
  }
}

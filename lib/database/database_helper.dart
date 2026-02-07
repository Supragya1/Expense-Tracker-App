import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/due_model.dart';
import '../models/account_model.dart';

/// Database Helper - Manages SQLite operations for the app
/// Implements CRUD with automatic balance recalculation
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('road_ronin_finance.db');
    return _database!;
  }

  /// Initialize database with tables
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create all tables
  Future<void> _createDB(Database db, int version) async {
    // 1. Accounts Table - Tracks bank balances
    await db.execute('''
      CREATE TABLE accounts (
        bank_name TEXT PRIMARY KEY,
        current_balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 2. Transactions Table - The main ledger
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        payment_app TEXT,
        receiver_name TEXT,
        description TEXT,
        timestamp INTEGER NOT NULL,
        category TEXT,
        balance_snapshot REAL
      )
    ''');

    // 3. Dues Table - Money to collect/give
    await db.execute('''
      CREATE TABLE dues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        due_date INTEGER,
        status TEXT DEFAULT 'PENDING',
        created_at INTEGER NOT NULL
      )
    ''');

    // Insert default bank accounts
    await db.insert('accounts', {'bank_name': 'HDFC', 'current_balance': 0.0});
    await db.insert('accounts', {'bank_name': 'SBI', 'current_balance': 0.0});
    await db.insert('accounts', {'bank_name': 'ICICI', 'current_balance': 0.0});
    await db.insert('accounts', {'bank_name': 'Axis', 'current_balance': 0.0});
    await db.insert('accounts', {'bank_name': 'Paytm', 'current_balance': 0.0});
    await db.insert('accounts', {'bank_name': 'Other', 'current_balance': 0.0});
  }

  // ============================================
  // TRANSACTION OPERATIONS
  // ============================================

  /// Insert new transaction with balance calculation
  Future<int> createTransaction(TransactionModel tx, {double? smsBalance}) async {
    final db = await database;

    // Get current balance for this bank
    double currentBal = await getBankBalance(tx.bankName);

    // Determine new balance
    double newBalance;
    if (smsBalance != null && smsBalance > 0) {
      // Priority 1: Use exact balance from SMS
      newBalance = smsBalance;
    } else {
      // Priority 2: Calculate manually
      if (tx.type == "CREDIT") {
        newBalance = currentBal + tx.amount;
      } else {
        newBalance = currentBal - tx.amount;
      }
    }

    // Create transaction with balance snapshot
    final txWithBalance = tx.copyWith(balanceSnapshot: newBalance);
    final id = await db.insert('transactions', txWithBalance.toMap());

    // Update bank's current balance
    await _updateBankBalance(tx.bankName, newBalance);

    return id;
  }

  /// Get all transactions sorted by newest first
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Get transactions for a specific date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Update existing transaction
  Future<void> updateTransaction(TransactionModel tx) async {
    final db = await database;

    await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );

    // Recalculate all balances from this point forward
    await _recalculateBalances(tx.bankName, tx.timestamp);
  }

  /// Delete transaction
  Future<void> deleteTransaction(int id, String bankName, DateTime date) async {
    final db = await database;

    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);

    // Recalculate balances after deletion
    await _recalculateBalances(bankName, date);
  }

  /// THE RIPPLE-EFFECT FIXER
  /// Recalculates balance_snapshot for all transactions after a given date
  Future<void> _recalculateBalances(String bankName, DateTime fromDate) async {
    final db = await database;

    // A. Find the last correct balance BEFORE the edited date
    final lastCorrectTx = await db.query(
      'transactions',
      where: 'bank_name = ? AND timestamp < ?',
      whereArgs: [bankName, fromDate.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    double runningBalance = 0.0;
    if (lastCorrectTx.isNotEmpty) {
      runningBalance = (lastCorrectTx.first['balance_snapshot'] as num?)?.toDouble() ?? 0.0;
    }

    // B. Fetch ALL transactions from the edited date onwards
    final futureTransactions = await db.query(
      'transactions',
      where: 'bank_name = ? AND timestamp >= ?',
      whereArgs: [bankName, fromDate.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );

    // C. Recalculate each one using Batch for efficiency
    final batch = db.batch();

    for (final row in futureTransactions) {
      final amount = (row['amount'] as num).toDouble();
      final type = row['type'] as String;
      final id = row['id'] as int;

      // Apply debit/credit
      if (type == "CREDIT") {
        runningBalance += amount;
      } else {
        runningBalance -= amount;
      }

      // Update this row
      batch.update(
        'transactions',
        {'balance_snapshot': runningBalance},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);

    // D. Update account's head balance
    await _updateBankBalance(bankName, runningBalance);
  }

  // ============================================
  // ACCOUNT OPERATIONS
  // ============================================

  /// Get balance for a specific bank
  Future<double> getBankBalance(String bankName) async {
    final db = await database;
    final result = await db.query(
      'accounts',
      where: 'bank_name = ?',
      whereArgs: [bankName],
    );

    if (result.isEmpty) {
      // Bank doesn't exist, create it
      await db.insert('accounts', {'bank_name': bankName, 'current_balance': 0.0});
      return 0.0;
    }

    return (result.first['current_balance'] as num).toDouble();
  }

  /// Update bank balance
  Future<void> _updateBankBalance(String bankName, double balance) async {
    final db = await database;
    await db.insert(
      'accounts',
      {'bank_name': bankName, 'current_balance': balance},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all accounts
  Future<List<AccountModel>> getAllAccounts() async {
    final db = await database;
    final result = await db.query('accounts');
    return result.map((map) => AccountModel.fromMap(map)).toList();
  }

  /// Get total balance across all banks
  Future<double> getTotalBalance() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(current_balance) as total FROM accounts',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ============================================
  // ANALYTICS
  // ============================================

  /// Get total spent this month
  Future<double> getMonthlySpent() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM transactions 
      WHERE type = 'DEBIT' 
      AND timestamp BETWEEN ? AND ?
      ''',
      [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total earned this month
  Future<double> getMonthlyEarned() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM transactions 
      WHERE type = 'CREDIT' 
      AND timestamp BETWEEN ? AND ?
      ''',
      [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get today's transactions
  Future<List<TransactionModel>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  // ============================================
  // DUES OPERATIONS
  // ============================================

  /// Create a new due
  Future<int> createDue(DueModel due) async {
    final db = await database;
    return await db.insert('dues', due.toMap());
  }

  /// Get all dues
  Future<List<DueModel>> getAllDues({String? status}) async {
    final db = await database;
    
    String? where;
    List<dynamic>? whereArgs;
    
    if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    }
    
    final result = await db.query(
      'dues',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return result.map((map) => DueModel.fromMap(map)).toList();
  }

  /// Get pending dues only
  Future<List<DueModel>> getPendingDues() async {
    return getAllDues(status: 'PENDING');
  }

  /// Get matching dues for smart settlement
  Future<List<DueModel>> getMatchingDues(double amount, String transactionType) async {
    final db = await database;
    
    // If incoming (CREDIT) -> look for TO_COLLECT
    // If outgoing (DEBIT) -> look for TO_GIVE
    final dueType = transactionType == "CREDIT" ? "TO_COLLECT" : "TO_GIVE";
    
    final result = await db.query(
      'dues',
      where: 'type = ? AND status = ? AND amount BETWEEN ? AND ?',
      whereArgs: [dueType, 'PENDING', amount - 50, amount + 50],
      orderBy: 'created_at DESC',
    );
    
    return result.map((map) => DueModel.fromMap(map)).toList();
  }

  /// Mark due as settled
  Future<void> settleDue(int dueId) async {
    final db = await database;
    await db.update(
      'dues',
      {'status': 'CLEARED'},
      where: 'id = ?',
      whereArgs: [dueId],
    );
  }

  /// Update due
  Future<void> updateDue(DueModel due) async {
    final db = await database;
    await db.update(
      'dues',
      due.toMap(),
      where: 'id = ?',
      whereArgs: [due.id],
    );
  }

  /// Delete due
  Future<void> deleteDue(int dueId) async {
    final db = await database;
    await db.delete('dues', where: 'id = ?', whereArgs: [dueId]);
  }

  /// Get total amount to collect
  Future<double> getTotalToCollect() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM dues WHERE type = 'TO_COLLECT' AND status = 'PENDING'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total amount to give
  Future<double> getTotalToGive() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM dues WHERE type = 'TO_GIVE' AND status = 'PENDING'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

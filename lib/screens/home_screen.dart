import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';

/// Home Screen - Main dashboard with summary cards and daily timeline
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> _transactions = [];
  double _totalBalance = 0;
  double _monthlySpent = 0;
  double _monthlyEarned = 0;
  double _toCollect = 0;
  double _toGive = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;
      
      final transactions = await db.getAllTransactions();
      final totalBalance = await db.getTotalBalance();
      final monthlySpent = await db.getMonthlySpent();
      final monthlyEarned = await db.getMonthlyEarned();
      final toCollect = await db.getTotalToCollect();
      final toGive = await db.getTotalToGive();

      setState(() {
        _transactions = transactions;
        _totalBalance = totalBalance;
        _monthlySpent = monthlySpent;
        _monthlyEarned = monthlyEarned;
        _toCollect = toCollect;
        _toGive = toGive;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Road Ronin Finance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, '/add_transaction')
                .then((_) => _loadData()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Summary Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Top Row: Balance & This Month
                          Row(
                            children: [
                              Expanded(
                                child: SummaryCard(
                                  title: 'Total Balance',
                                  value: currencyFormat.format(_totalBalance),
                                  icon: Icons.account_balance_wallet,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SummaryCard(
                                  title: 'Monthly Spent',
                                  value: currencyFormat.format(_monthlySpent),
                                  icon: Icons.arrow_upward,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Bottom Row: Earned & Dues
                          Row(
                            children: [
                              Expanded(
                                child: SummaryCard(
                                  title: 'Monthly Earned',
                                  value: currencyFormat.format(_monthlyEarned),
                                  icon: Icons.arrow_downward,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SummaryCard(
                                  title: 'Dues',
                                  value: '↓${currencyFormat.format(_toCollect)} ↑${currencyFormat.format(_toGive)}',
                                  icon: Icons.swap_horiz,
                                  color: Colors.orange,
                                  onTap: () => Navigator.pushNamed(context, '/dues')
                                      .then((_) => _loadData()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_transactions.length} items',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Transactions List with Date Headers
                  _transactions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'SMS transactions will appear here automatically',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tx = _transactions[index];
                              final showHeader = index == 0 ||
                                  !_isSameDay(_transactions[index - 1].timestamp, tx.timestamp);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showHeader)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                      child: Text(
                                        _formatDateHeader(tx.timestamp),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  TransactionTile(
                                    transaction: tx,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/add_transaction',
                                      arguments: {'transaction': tx, 'isEdit': true},
                                    ).then((_) => _loadData()),
                                    onLongPress: () => _showOptionsSheet(tx),
                                  ),
                                ],
                              );
                            },
                            childCount: _transactions.length,
                          ),
                        ),

                  // Bottom Padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_transaction')
            .then((_) => _loadData()),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/dues').then((_) => _loadData());
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Dues',
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Transaction'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    '/add_transaction',
                    arguments: {'transaction': tx, 'isEdit': true},
                  ).then((_) => _loadData());
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Transaction'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(tx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete this ₹${tx.amount.toStringAsFixed(0)} transaction? This will recalculate your balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.deleteTransaction(
                tx.id!,
                tx.bankName,
                tx.timestamp,
              );
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/due_model.dart';

/// Add/Edit Transaction Screen
/// Handles both new transactions (from SMS or manual) and editing existing ones
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _receiverController = TextEditingController();

  // Form state
  String _type = 'DEBIT';
  String _bankName = 'HDFC';
  String _paymentApp = 'GPay';
  String _category = 'Uncategorized';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Edit mode
  bool _isEditing = false;
  int? _existingId;
  double? _smsBalance;

  // Smart match for dues
  List<DueModel> _matchingDues = [];
  DueModel? _selectedDueToSettle;

  // Options
  final List<String> _banks = ['HDFC', 'SBI', 'ICICI', 'Axis', 'Kotak', 'Paytm', 'Other'];
  final List<String> _apps = ['GPay', 'PhonePe', 'BHIM', 'Card', 'NetBanking', 'Cash', 'Other'];
  final List<String> _categories = [
    'Uncategorized', 'Food', 'Travel', 'Shopping', 'Bills', 
    'Entertainment', 'Health', 'Education', 'Salary', 'Freelance', 'Other'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseArguments();
  }

  void _parseArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null) return;

    if (args is Map<String, dynamic>) {
      // From notification - SMS data
      if (args['fromNotification'] == true) {
        _amountController.text = args['amount'] ?? '';
        _bankName = args['bankName'] ?? 'HDFC';
        _type = args['type'] == 'CREDIT' ? 'CREDIT' : 'DEBIT';
        _receiverController.text = args['receiverName'] ?? '';
        _smsBalance = double.tryParse(args['balance'] ?? '');
        
        // Check for matching dues
        _checkMatchingDues();
      }
      
      // Edit mode - existing transaction
      if (args['isEdit'] == true && args['transaction'] != null) {
        final tx = args['transaction'] as TransactionModel;
        _isEditing = true;
        _existingId = tx.id;
        _amountController.text = tx.amount.toString();
        _type = tx.type;
        _bankName = tx.bankName;
        _paymentApp = tx.paymentApp;
        _receiverController.text = tx.receiverName;
        _descController.text = tx.description;
        _category = tx.category;
        _selectedDate = tx.timestamp;
        _selectedTime = TimeOfDay.fromDateTime(tx.timestamp);
      }
    }
  }

  Future<void> _checkMatchingDues() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final dues = await DatabaseHelper.instance.getMatchingDues(amount, _type);
    setState(() => _matchingDues = dues);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Transaction Type Toggle
            _buildTypeToggle(),
            const SizedBox(height: 20),

            // Amount Field
            _buildAmountField(),
            const SizedBox(height: 16),

            // Receiver/Merchant
            _buildTextField(
              controller: _receiverController,
              label: _type == 'CREDIT' ? 'From (Person/Source)' : 'To (Merchant/Person)',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // Bank & App Row
            Row(
              children: [
                Expanded(child: _buildDropdown('Bank', _bankName, _banks, (v) => setState(() => _bankName = v!))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('App', _paymentApp, _apps, (v) => setState(() => _paymentApp = v!))),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            _buildDropdown('Category', _category, _categories, (v) => setState(() => _category = v!)),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descController,
              label: 'Description (Optional)',
              icon: Icons.notes,
              hint: 'What was this for?',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Date & Time
            _buildDateTimeRow(),
            const SizedBox(height: 20),

            // Smart Match for Dues
            if (_matchingDues.isNotEmpty) _buildDuesMatcher(),

            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _type = 'DEBIT';
                _checkMatchingDues();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == 'DEBIT' ? Colors.red[400] : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: _type == 'DEBIT' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expense',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _type == 'DEBIT' ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _type = 'CREDIT';
                _checkMatchingDues();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == 'CREDIT' ? Colors.green[400] : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: _type == 'CREDIT' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Income',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _type == 'CREDIT' ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        prefixText: '₹ ',
        prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        hintText: '0',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.withOpacity(0.5), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter amount';
        if (double.tryParse(value) == null) return 'Invalid amount';
        return null;
      },
      onChanged: (_) => _checkMatchingDues(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.withOpacity(0.5), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Text(dateFormat.format(_selectedDate)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Text(timeFormat.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuesMatcher() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Settle a Due?',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._matchingDues.map((due) {
            final isSelected = _selectedDueToSettle?.id == due.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDueToSettle = isSelected ? null : due;
                  if (!isSelected) {
                    _descController.text = 'Settled: ${due.description}';
                    _receiverController.text = due.personName;
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange[100] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(due.personName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (due.description.isNotEmpty)
                            Text(due.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Text(
                      '₹${due.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveTransaction,
      style: ElevatedButton.styleFrom(
        backgroundColor: _type == 'CREDIT' ? Colors.green : Colors.red[400],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        _isEditing ? 'UPDATE TRANSACTION' : 'SAVE TRANSACTION',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final timestamp = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final tx = TransactionModel(
      id: _existingId,
      amount: double.parse(_amountController.text),
      type: _type,
      bankName: _bankName,
      paymentApp: _paymentApp,
      receiverName: _receiverController.text.isNotEmpty ? _receiverController.text : 'Unknown',
      description: _descController.text,
      timestamp: timestamp,
      category: _category,
    );

    try {
      final db = DatabaseHelper.instance;

      if (_isEditing) {
        await db.updateTransaction(tx);
      } else {
        await db.createTransaction(tx, smsBalance: _smsBalance);
      }

      // Settle due if selected
      if (_selectedDueToSettle != null) {
        await db.settleDue(_selectedDueToSettle!.id!);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Transaction updated' : 'Transaction saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _receiverController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/due_model.dart';

/// Add Due Screen - Create a new due (To Collect or To Give)
class AddDueScreen extends StatefulWidget {
  const AddDueScreen({super.key});

  @override
  State<AddDueScreen> createState() => _AddDueScreenState();
}

class _AddDueScreenState extends State<AddDueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  String _type = 'TO_COLLECT';
  DateTime? _dueDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Add Due'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type Toggle
            _buildTypeToggle(),
            const SizedBox(height: 24),

            // Person Name
            _buildTextField(
              controller: _personNameController,
              label: _type == 'TO_COLLECT' ? 'Who owes you?' : 'Who do you owe?',
              icon: Icons.person_outline,
              hint: 'Person or company name',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            _buildTextField(
              controller: _amountController,
              label: 'Amount',
              icon: Icons.currency_rupee,
              hint: '0',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descController,
              label: 'Description (Optional)',
              icon: Icons.notes,
              hint: 'What is this for?',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Due Date
            _buildDatePicker(),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveDue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'TO_COLLECT' ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _type == 'TO_COLLECT' ? 'ADD RECEIVABLE' : 'ADD PAYABLE',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
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
              onTap: () => setState(() => _type = 'TO_COLLECT'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == 'TO_COLLECT' ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.call_received,
                      size: 20,
                      color: _type == 'TO_COLLECT' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'To Collect',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _type == 'TO_COLLECT' ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = 'TO_GIVE'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == 'TO_GIVE' ? Colors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.call_made,
                      size: 20,
                      color: _type == 'TO_GIVE' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'To Give',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _type == 'TO_GIVE' ? Colors.white : Colors.grey[600],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final dateFormat = DateFormat('MMM d, y');

    return GestureDetector(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date (Optional)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dueDate != null ? dateFormat.format(_dueDate!) : 'No date set',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            if (_dueDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _dueDate = null),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _saveDue() async {
    if (!_formKey.currentState!.validate()) return;

    final due = DueModel(
      personName: _personNameController.text.trim(),
      amount: double.parse(_amountController.text),
      type: _type,
      description: _descController.text.trim(),
      dueDate: _dueDate,
    );

    try {
      await DatabaseHelper.instance.createDue(due);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _type == 'TO_COLLECT'
                  ? '₹${due.amount.toStringAsFixed(0)} to collect from ${due.personName}'
                  : '₹${due.amount.toStringAsFixed(0)} to give to ${due.personName}',
            ),
          ),
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
    _personNameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

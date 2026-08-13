import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late Future<List<Map<String, dynamic>>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _refreshExpenses();
  }

  void _refreshExpenses() {
    setState(() {
      _expensesFuture = DatabaseHelper.instance.readAllExpenses();
    });
  }

  void _showAddExpenseDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (\$)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (descCtrl.text.isNotEmpty && amount != null) {
                await DatabaseHelper.instance.createExpense(descCtrl.text, amount);
                if (mounted) Navigator.pop(context);
                _refreshExpenses();
              }
            },
            child: const Text('Save Expense'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expenses Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
              ElevatedButton.icon(
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Log Expense'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No expenses logged yet.'));
                  }
                  
                  final expenses = snapshot.data!;
                  return ListView.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final dateStr = expense['date'] as String;
                      final date = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
                      
                      return _buildExpenseItem(
                        expense['description'], 
                        expense['amount'] as double, 
                        date
                      );
                    },
                  );
                }
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String desc, double amount, String date) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        child: const Icon(Icons.receipt, color: Colors.orange),
      ),
      title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text('-\$\${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
    );
  }
}

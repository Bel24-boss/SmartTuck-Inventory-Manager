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
  
  double _revenue = 0.0;
  double _cogs = 0.0;
  double _expensesTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _expensesFuture = DatabaseHelper.instance.readAllExpenses();
    });
    _calculateFinancials();
  }

  Future<void> _calculateFinancials() async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Revenue
    final sales = await db.query('sales');
    double rev = 0.0;
    for (var s in sales) {
      rev += (s['total_amount'] as num).toDouble();
    }

    // 2. Expenses
    final exps = await db.query('expenses');
    double expTotal = 0.0;
    for (var e in exps) {
      expTotal += (e['amount'] as num).toDouble();
    }

    // 3. COGS (Approximation using current buying prices of sold items)
    final saleItems = await db.rawQuery('''
      SELECT si.quantity, p.buyingPrice 
      FROM sale_items si 
      JOIN products p ON si.product_id = p.id
    ''');
    
    double cogsCalc = 0.0;
    for (var item in saleItems) {
      int qty = (item['quantity'] as num).toInt();
      double bp = (item['buyingPrice'] as num).toDouble();
      cogsCalc += (qty * bp);
    }

    if (mounted) {
      setState(() {
        _revenue = rev;
        _expensesTotal = expTotal;
        _cogs = cogsCalc;
      });
    }
  }

  void _showAddExpenseDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Miscellaneous';
    final categories = ['Miscellaneous', 'Rent', 'Utilities', 'Salaries', 'Repairs', 'Supplies'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: const Color(0xFFF0F1F5),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Expense', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => category = v);
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontSize: 16)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final amount = double.tryParse(amountCtrl.text);
                            if (descCtrl.text.isNotEmpty && amount != null) {
                              final finalDesc = '[$category] ${descCtrl.text}';
                              await DatabaseHelper.instance.createExpense(finalDesc, amount);
                              if (mounted) Navigator.pop(context);
                              _refreshData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Save Expense', style: TextStyle(fontSize: 16)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    double grossProfit = _revenue - _cogs;
    double netProfit = grossProfit - _expensesTotal;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record Expense'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expenses & Financials',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              // Financial Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF143E26), // Dark green from the UI
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('FINANCIAL SUMMARY (ALL TIME)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric('Revenue', '\$${_revenue.toStringAsFixed(2)}', const Color(0xFF81C784)),
                        _buildMetric('COGS', '\$${_cogs.toStringAsFixed(2)}', const Color(0xFFFFB74D)),
                        _buildMetric('Gross Profit', '\$${grossProfit.toStringAsFixed(2)}', const Color(0xFF81C784)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric('Expenses', '\$${_expensesTotal.toStringAsFixed(2)}', const Color(0xFFE57373)),
                        const Spacer(),
                        _buildMetric('Net Profit', '\$${netProfit.toStringAsFixed(2)}', Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Recent Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _expensesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No expenses logged yet.', style: TextStyle(color: Colors.grey)));
                    }
                    
                    final expenses = snapshot.data!;
                    return ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final dateStr = expense['date'] as String;
                        final date = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
                        
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long, color: Colors.red),
                            ),
                            title: Text(expense['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            trailing: Text("-\$${(expense['amount'] as num).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                          ),
                        );
                      },
                    );
                  }
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

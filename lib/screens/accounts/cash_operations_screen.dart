import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class CashOperationsScreen extends StatefulWidget {
  const CashOperationsScreen({super.key});

  @override
  State<CashOperationsScreen> createState() => _CashOperationsScreenState();
}

class _CashOperationsScreenState extends State<CashOperationsScreen> {
  List<Map<String, dynamic>> _operations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  Future<void> _loadOperations() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final ops = await db.query('cash_operations', orderBy: 'id DESC');
    setState(() {
      _operations = ops;
      _isLoading = false;
    });
  }

  void _showNewOperationDialog() {
    final typeCtrl = TextEditingController(text: 'Cash-In');
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ecocashNumCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Mobile Money Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: 'Cash-In',
                items: ['Cash-In', 'Cash-Out'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => typeCtrl.text = val!,
                decoration: const InputDecoration(labelText: 'Transaction Type'),
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name (Optional)')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number (Optional)')),
              TextField(controller: ecocashNumCtrl, decoration: const InputDecoration(labelText: 'EcoCash Number')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (\$)'), keyboardType: TextInputType.number),
              TextField(controller: feeCtrl, decoration: const InputDecoration(labelText: 'Service Fee (\$)'), keyboardType: TextInputType.number),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (Optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isNotEmpty && ecocashNumCtrl.text.isNotEmpty) {
                await DatabaseHelper.instance.createCashOperation(
                  typeCtrl.text,
                  nameCtrl.text.isEmpty ? null : nameCtrl.text,
                  phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                  ecocashNumCtrl.text,
                  double.parse(amountCtrl.text),
                  double.tryParse(feeCtrl.text) ?? 0.0,
                  notesCtrl.text.isEmpty ? null : notesCtrl.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadOperations();
                }
              }
            },
            child: const Text('Save Transaction'),
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
              const Text('EcoCash Agent Operations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showNewOperationDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Transaction'),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _operations.length,
                    itemBuilder: (context, index) {
                      final op = _operations[index];
                      final isCashIn = op['type'] == 'Cash-In';
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCashIn ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          title: Text("\${op['type']} - \$\${op['amount']} (EcoCash: \${op['ecocash_number']})"),
                          subtitle: Text("Fee: \$\${op['fee']} | Name: \${op['customer_name'] ?? 'N/A'}\nDate: \${op['date']}"),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

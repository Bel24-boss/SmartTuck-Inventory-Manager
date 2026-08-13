import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class ChangeRegisterScreen extends StatefulWidget {
  const ChangeRegisterScreen({super.key});

  @override
  State<ChangeRegisterScreen> createState() => _ChangeRegisterScreenState();
}

class _ChangeRegisterScreenState extends State<ChangeRegisterScreen> {
  List<Map<String, dynamic>> _changeRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChangeRegister();
  }

  Future<void> _loadChangeRegister() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final records = await db.query('change_register', orderBy: 'id DESC');
    setState(() {
      _changeRecords = records;
      _isLoading = false;
    });
  }

  Future<void> _markAsPaid(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('change_register', {'status': 'Paid'}, where: 'id = ?', whereArgs: [id]);
    _loadChangeRegister();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change & Credits Register',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _changeRecords.length,
              itemBuilder: (context, index) {
                final record = _changeRecords[index];
                final isPaid = record['status'] == 'Paid';
                return Card(
                  child: ListTile(
                    leading: Icon(
                      isPaid ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: isPaid ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    title: Text("\${record['customer_name']} (Phone: \${record['phone'] ?? 'N/A'})"),
                    subtitle: Text("Amount: \$\${record['amount_owed']} | Status: \${record['status']}\nDate: \${record['date']}"),
                    trailing: isPaid ? null : ElevatedButton(
                      onPressed: () => _markAsPaid(record['id']),
                      child: const Text('Mark as Paid'),
                    ),
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

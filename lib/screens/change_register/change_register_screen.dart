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
    if (mounted) {
      setState(() {
        _changeRecords = records;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsPaid(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('change_register', {'status': 'Paid'}, where: 'id = ?', whereArgs: [id]);
    _loadChangeRegister();
  }

  void _showRecordChangeDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF0F1F5),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Record Change Owed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 32),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  filled: false,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount Owed',
                  filled: false,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                ),
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
                      if (nameCtrl.text.isNotEmpty && amount != null) {
                        final db = await DatabaseHelper.instance.database;
                        await db.insert('change_register', {
                          'customer_name': nameCtrl.text,
                          'amount_owed': amount,
                          'date': DateTime.now().toIso8601String(),
                          'status': 'Pending'
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _loadChangeRegister();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Save Record', style: TextStyle(fontSize: 16)),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordChangeDialog,
        backgroundColor: const Color(0xFF707687), // Muted grey-blue from screenshot
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, color: Colors.black87),
        label: const Text('Record Change', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change Register',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _changeRecords.isEmpty
                          ? Center(child: Text('No change records found.', style: TextStyle(color: Colors.grey[600])))
                          : ListView.builder(
                              itemCount: _changeRecords.length,
                              itemBuilder: (context, index) {
                                final record = _changeRecords[index];
                                final isPaid = record['status'] == 'Paid';
                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPaid ? Icons.check_circle : Icons.warning_amber_rounded,
                                          color: isPaid ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                      title: Text(record['customer_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          "Amount Owed: \$${(record['amount_owed'] as num).toStringAsFixed(2)}\nStatus: ${record['status']}",
                                          style: TextStyle(color: Colors.grey[600], height: 1.4),
                                        ),
                                      ),
                                      trailing: isPaid 
                                          ? null 
                                          : ElevatedButton(
                                              onPressed: () => _markAsPaid(record['id']),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue.withOpacity(0.1),
                                                foregroundColor: Colors.blue[700],
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              child: const Text('Mark Paid'),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  void _showDeleteChangeDialog(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this change record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteChangeRecord(record['id']);
              if (context.mounted) {
                Navigator.pop(context);
                _loadChangeRegister();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

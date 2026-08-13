import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../opening_screen.dart';
import '../../theme/app_theme.dart';

class CloseShopScreen extends StatefulWidget {
  const CloseShopScreen({super.key});

  @override
  State<CloseShopScreen> createState() => _CloseShopScreenState();
}

class _CloseShopScreenState extends State<CloseShopScreen> {
  final _actualCashCtrl = TextEditingController();
  final _actualEcocashCtrl = TextEditingController();
  
  Map<String, dynamic>? _session;
  double _expectedCash = 0.0;
  double _expectedEcocash = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateExpected();
  }

  Future<void> _calculateExpected() async {
    final db = await DatabaseHelper.instance.database;
    final session = await DatabaseHelper.instance.getActiveSession();
    
    if (session == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Calculate Sales (Cash vs Ecocash)
    final sales = await db.query('sales', where: 'date >= ?', whereArgs: [session['date']]);
    double cashSales = 0.0;
    double ecoSales = 0.0;

    for (var s in sales) {
      final amt = s['total_amount'] as double;
      if (s['payment_method'] == 'Cash') cashSales += amt;
      if (s['payment_method'] == 'EcoCash') ecoSales += amt;
      // Note: Mixed payments are complex, simplified here for demonstration
    }

    // Cash operations
    final cashOps = await db.query('cash_operations', where: 'date >= ?', whereArgs: [session['date']]);
    double cashInOps = 0.0;
    double cashOutOps = 0.0;
    for (var op in cashOps) {
      final amt = op['amount'] as double;
      final fee = op['fee'] as double;
      if (op['type'] == 'Cash-In') {
        cashInOps += (amt + fee); // We received cash, gave ecocash
      } else {
        cashOutOps += amt; // We gave cash, received ecocash + fee
      }
    }

    setState(() {
      _session = session;
      _expectedCash = (session['opening_cash'] as double) + cashSales + cashInOps - cashOutOps;
      _expectedEcocash = (session['opening_ecocash'] as double) + ecoSales - cashInOps + cashOutOps;
      _isLoading = false;
    });
  }

  void _confirmClose() async {
    final actualCash = double.tryParse(_actualCashCtrl.text);
    final actualEcocash = double.tryParse(_actualEcocashCtrl.text);

    if (actualCash == null || actualEcocash == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amounts')));
      return;
    }

    await DatabaseHelper.instance.closeSession(
      _session!['id'] as int,
      actualCash,
      actualEcocash,
      _expectedCash,
      _expectedEcocash,
    );

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OpeningScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('End of Day Reconciliation')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('System Expected Balances', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.grey[200],
                title: const Text('Expected Cash in Till'),
                trailing: Text('\$${_expectedCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: Colors.grey[200],
                title: const Text('Expected EcoCash Balance'),
                trailing: Text('\$${_expectedEcocash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              const Text('Enter Physical Counts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 16),
              TextField(
                controller: _actualCashCtrl,
                decoration: const InputDecoration(labelText: 'Actual Physical Cash (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _actualEcocashCtrl,
                decoration: const InputDecoration(labelText: 'Actual EcoCash Balance (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _confirmClose,
                  icon: const Icon(Icons.lock_clock),
                  label: const Text('Calculate Overs/Shortages & Close Shop', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

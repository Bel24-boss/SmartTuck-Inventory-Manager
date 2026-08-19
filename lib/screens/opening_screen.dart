import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'main_layout.dart';
import '../theme/app_theme.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  final _cashCtrl = TextEditingController();
  final _ecocashCtrl = TextEditingController();
  final _floatOutCtrl = TextEditingController();
  final _floatChangeCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _openShop() async {
    final cash = double.tryParse(_cashCtrl.text);
    final ecocash = double.tryParse(_ecocashCtrl.text);
    final floatOut = double.tryParse(_floatOutCtrl.text);
    final floatChange = double.tryParse(_floatChangeCtrl.text);

    if (cash == null || ecocash == null || floatOut == null || floatChange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields with valid numbers')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.openSession(
        cash, 
        ecocash, 
        floatOut, 
        floatChange,
        customDate: _selectedDate.toIso8601String(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainLayout()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront, size: 64, color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    const Text('Good Morning!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('Let\'s open the shop for the day.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                const SizedBox(width: 12),
                                Text(
                                  'Recording Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const Icon(Icons.edit, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: _cashCtrl,
                      decoration: const InputDecoration(labelText: 'Opening Cash in Till (\$)', prefixIcon: Icon(Icons.attach_money)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ecocashCtrl,
                      decoration: const InputDecoration(labelText: 'EcoCash Wallet Balance (\$)', prefixIcon: Icon(Icons.phone_android)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _floatOutCtrl,
                      decoration: const InputDecoration(labelText: 'Float Available for Cash-out (\$)', prefixIcon: Icon(Icons.money_off)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _floatChangeCtrl,
                      decoration: const InputDecoration(labelText: 'Float Available for Change (\$)', prefixIcon: Icon(Icons.currency_exchange)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _openShop,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Open Shop', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../models/product.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(() {
      _filterProducts(_searchCtrl.text);
    });
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper.instance.readAllProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
    });
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _allProducts);
      return;
    }
    setState(() {
      _filteredProducts = _allProducts.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  double get _totalAmount {
    return _cart.entries.fold(0.0, (sum, entry) => sum + (entry.key.price * entry.value));
  }

  void _addToCart(Product p) {
    setState(() {
      _cart[p] = (_cart[p] ?? 0) + 1;
    });
  }

  void _decrementCart(Product p) {
    setState(() {
      if (_cart[p]! > 1) {
        _cart[p] = _cart[p]! - 1;
      } else {
        _cart.remove(p);
      }
    });
  }

  void _showCheckoutModal() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => CheckoutModal(
        totalAmount: _totalAmount,
        cart: _cart,
        onComplete: () {
          setState(() {
            _cart.clear();
            _searchCtrl.clear();
            _loadProducts();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    // Left side: Search & Products
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                labelText: 'Search "bread"',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // fewer columns on mobile
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final p = _filteredProducts[index];
                                  return InkWell(
                                    onTap: () => _addToCart(p),
                                    child: Card(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
                                            Text('Stock: ${p.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right side: Cart & Checkout
                    Expanded(
                      flex: 2, // give equal flex on mobile
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Current Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _cart.isEmpty
                                  ? const Center(child: Text('Cart is empty', style: TextStyle(color: Colors.grey, fontSize: 16)))
                                  : ListView(
                                      children: _cart.entries.map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(e.key.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), onPressed: () => _decrementCart(e.key)),
                                                Text('\$${e.value}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.grey), onPressed: () => _addToCart(e.key)),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 60,
                                              child: Text('\$${(e.key.price * e.value).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                                    ),
                            ),
                            const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('\$${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF143E26))),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _cart.isEmpty ? null : _showCheckoutModal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cart.isEmpty ? Colors.grey[300] : const Color(0xFF143E26),
                                  foregroundColor: _cart.isEmpty ? Colors.grey[600] : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 0,
                                ),
                                child: const Text('Checkout', style: TextStyle(fontSize: 18)),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }

              // Desktop/Tablet view
              return Row(
                children: [
                  // Left side: Search & Products
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              labelText: 'Search "bread"',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final p = _filteredProducts[index];
                                return InkWell(
                                  onTap: () => _addToCart(p),
                                  child: Card(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          const SizedBox(height: 8),
                                          Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text('Stock: ${p.quantity}', style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right side: Cart & Checkout
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text('Current Cart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _cart.isEmpty
                                ? const Center(child: Text('Cart is empty', style: TextStyle(color: Colors.grey, fontSize: 18)))
                                : ListView(
                                    children: _cart.entries.map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(e.key.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                const SizedBox(height: 4),
                                                Text('\$${e.key.price.toStringAsFixed(2)} each', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), onPressed: () => _decrementCart(e.key)),
                                              Text('\$${e.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.grey), onPressed: () => _addToCart(e.key)),
                                            ],
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: Text('\$${(e.key.price * e.value).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                          ),
                          const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('\$${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF143E26))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _cart.isEmpty ? null : _showCheckoutModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cart.isEmpty ? Colors.grey[300] : const Color(0xFF143E26),
                                foregroundColor: _cart.isEmpty ? Colors.grey[600] : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: const Text('Checkout', style: TextStyle(fontSize: 22)),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              );
            return const Center(child: Text('Desktop layout coming soon'));
          },
        );
  }
}

class CheckoutModal extends StatefulWidget {
  final double totalAmount;
  final Map<Product, int> cart;
  final VoidCallback onComplete;

  const CheckoutModal({super.key, required this.totalAmount, required this.cart, required this.onComplete});

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  String _paymentMethod = 'Cash';
  final _cashCtrl = TextEditingController();
  final _ecocashCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isProcessing = false;
  double _owedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_checkDebt);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_checkDebt);
    super.dispose();
  }

  Future<void> _checkDebt() async {
    final phone = _phoneCtrl.text;
    if (phone.length >= 8) {
      final records = await DatabaseHelper.instance.checkCustomerOwed(phone);
      double total = 0;
      for (var r in records) {
        total += r['amount_owed'] as double;
      }
      if (mounted) {
        setState(() {
          _owedAmount = total;
          if (_owedAmount != 0 && _customerCtrl.text.isEmpty && records.isNotEmpty) {
             _customerCtrl.text = records.first['customer_name'] as String;
          }
        });
      }
    } else {
      if (_owedAmount != 0 && mounted) {
        setState(() => _owedAmount = 0);
      }
    }
  }

  void _completeSale() async {
    setState(() => _isProcessing = true);
    try {
      double totalTendered = 0.0;
      if (_paymentMethod == 'Cash') {
        totalTendered = double.tryParse(_cashCtrl.text) ?? widget.totalAmount;
      } else if (_paymentMethod == 'EcoCash') {
        totalTendered = widget.totalAmount;
      } else if (_paymentMethod == 'Mixed') {
        final c = double.tryParse(_cashCtrl.text) ?? 0.0;
        final e = double.tryParse(_ecocashCtrl.text) ?? 0.0;
        totalTendered = c + e;
      }

      double change = totalTendered - widget.totalAmount;

      final db = await DatabaseHelper.instance.database;
      
      final saleId = await db.insert('sales', {
        'total_amount': widget.totalAmount,
        'date': DateTime.now().toIso8601String(),
        'payment_method': _paymentMethod,
        'cashier': 'Attendant'
      });

      for (var entry in widget.cart.entries) {
        await db.insert('sale_items', {
          'sale_id': saleId,
          'product_id': entry.key.id,
          'quantity': entry.value,
          'unit_price': entry.key.price
        });
        final newQuantity = entry.key.quantity - entry.value;
        await db.update('products', {'quantity': newQuantity}, where: 'id = ?', whereArgs: [entry.key.id]);
      }

      if (change != 0 && _customerCtrl.text.isNotEmpty) {
        await db.insert('change_register', {
          'customer_name': _customerCtrl.text,
          'phone': _phoneCtrl.text,
          'amount_owed': -change, // Negative means we owe them, positive means they owe us
          'status': 'Pending',
          'date': DateTime.now().toIso8601String()
        });
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale successful!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Checkout - \$${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _payButton('Cash', Icons.money),
                _payButton('EcoCash', Icons.phone_android),
                _payButton('Mixed', Icons.account_balance_wallet),
              ],
            ),
            const SizedBox(height: 24),
            if (_paymentMethod == 'Cash')
              TextField(
                controller: _cashCtrl,
                decoration: const InputDecoration(labelText: 'Cash Tendered (\$)'),
                keyboardType: TextInputType.number,
              ),
            if (_paymentMethod == 'Mixed')
              Row(
                children: [
                  Expanded(child: TextField(controller: _cashCtrl, decoration: const InputDecoration(labelText: 'Cash Part (\$)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _ecocashCtrl, decoration: const InputDecoration(labelText: 'EcoCash Part (\$)'), keyboardType: TextInputType.number)),
                ],
              ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('Change / Credit (Optional)', style: TextStyle(color: Colors.grey)),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Customer Phone (Checks for debts)')),
            TextField(controller: _customerCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
            TextField(controller: _reasonCtrl, decoration: const InputDecoration(labelText: 'Reason for Owed Change')),
            if (_owedAmount != 0)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                color: _owedAmount < 0 ? Colors.red[100] : Colors.green[100],
                child: Row(
                  children: [
                    Icon(_owedAmount < 0 ? Icons.warning : Icons.info, color: _owedAmount < 0 ? Colors.red : Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      _owedAmount < 0 
                        ? 'ALERT: You owe this customer \$${_owedAmount.abs().toStringAsFixed(2)} from a previous transaction!'
                        : 'ALERT: This customer owes you \$${_owedAmount.toStringAsFixed(2)}!',
                      style: TextStyle(color: _owedAmount < 0 ? Colors.red[900] : Colors.green[900], fontWeight: FontWeight.bold),
                    ))
                  ],
                ),
              )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isProcessing ? null : _completeSale,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Sale', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget _payButton(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 32),
            const SizedBox(height: 8),
            Text(method, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

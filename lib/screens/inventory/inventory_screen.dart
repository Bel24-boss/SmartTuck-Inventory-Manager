import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InventoryProvider>().fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: Colors.blue[600], // Match the vibrant blue FAB from the screenshot
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.products.isEmpty) {
                      return const Center(child: Text('No products in inventory.', style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        
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
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                radius: 24,
                                child: Text(product.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Stock: ${product.quantity} | Price:\n\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey[600], height: 1.4),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                                    onPressed: () => _showRestockDialog(context, product),
                                    tooltip: 'Restock',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.grey),
                                    onPressed: () {
                                      // Optional edit logic can go here
                                    },
                                    tooltip: 'Edit',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final buyingPriceCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final minStockCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF0F1F5),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Product', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 32),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name', filled: false, border: UnderlineInputBorder(), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)))),
                const SizedBox(height: 16),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity', filled: false, border: UnderlineInputBorder(), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextField(controller: buyingPriceCtrl, decoration: const InputDecoration(labelText: 'Buying Price', filled: false, border: UnderlineInputBorder(), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Selling Price', filled: false, border: UnderlineInputBorder(), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Minimum Stock Level', filled: false, border: UnderlineInputBorder(), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))), keyboardType: TextInputType.number),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontSize: 16))),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text;
                        final buyingPrice = double.tryParse(buyingPriceCtrl.text) ?? 0;
                        final price = double.tryParse(priceCtrl.text) ?? 0;
                        final qty = int.tryParse(qtyCtrl.text) ?? 0;
                        final minStock = int.tryParse(minStockCtrl.text) ?? 5;
                        
                        if (name.isNotEmpty) {
                          final product = Product(
                            name: name,
                            buyingPrice: buyingPrice,
                            price: price,
                            quantity: qty,
                            minimumStockLevel: minStock,
                            dateAdded: DateTime.now().toIso8601String(),
                          );
                          context.read<InventoryProvider>().addProduct(product);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Save Product', style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRestockDialog(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final supplierCtrl = TextEditingController(text: product.supplier ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restock ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyCtrl, decoration: InputDecoration(labelText: 'Quantity to add to ${product.name}'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Total Cost (\$)'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (qtyCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty && supplierCtrl.text.isNotEmpty) {
                await DatabaseHelper.instance.recordStockPurchase(
                  product.id!,
                  supplierCtrl.text,
                  int.parse(qtyCtrl.text),
                  double.parse(costCtrl.text),
                );
                if (context.mounted) {
                  context.read<InventoryProvider>().fetchProducts();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} restocked successfully!')));
                }
              }
            },
            child: const Text('Record Purchase'),
          ),
        ],
      ),
    );
  }
}

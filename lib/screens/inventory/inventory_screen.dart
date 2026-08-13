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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Inventory Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.products.isEmpty) {
                  return const Center(child: Text('No products in inventory.'));
                }
                return Card(
                  child: ListView.separated(
                    itemCount: provider.products.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = provider.products[index];
                      
                      // Stock Status Color Logic
                      Color stockColor;
                      if (product.quantity <= 0) {
                        stockColor = Colors.red[100]!; // Out of stock
                      } else if (product.quantity <= product.minimumStockLevel) {
                        stockColor = Colors.orange[100]!; // Running low
                      } else {
                        stockColor = Colors.green[50]!; // Enough stock
                      }

                      return Card(
                        color: stockColor,
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Qty: ${product.quantity}  |  Min: ${product.minimumStockLevel}  |  Barcode: ${product.barcode ?? "N/A"}\n'
                            '${product.quantity <= 0 ? "OUT OF STOCK" : product.quantity <= product.minimumStockLevel ? "LOW STOCK" : "IN STOCK"}',
                            style: TextStyle(
                              color: product.quantity <= 0 ? Colors.red[900] : product.quantity <= product.minimumStockLevel ? Colors.orange[900] : Colors.green[900],
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showRestockDialog(context, product),
                                icon: const Icon(Icons.add_shopping_cart, size: 16),
                                label: const Text('Restock'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => provider.deleteProduct(product.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final buyingPriceCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final minStockCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 16),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category (e.g., Drinks, Bread)')),
              const SizedBox(height: 16),
              TextField(controller: buyingPriceCtrl, decoration: const InputDecoration(labelText: 'Buying Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Min Stock Level'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier (Optional)')),
              const SizedBox(height: 16),
              TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode (Optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                final product = Product(
                  name: nameCtrl.text,
                  buyingPrice: double.tryParse(buyingPriceCtrl.text) ?? 0.0,
                  price: double.parse(priceCtrl.text),
                  quantity: int.parse(qtyCtrl.text),
                  minimumStockLevel: int.tryParse(minStockCtrl.text) ?? 10,
                  supplier: supplierCtrl.text.isNotEmpty ? supplierCtrl.text : null,
                  barcode: barcodeCtrl.text.isNotEmpty ? barcodeCtrl.text : null,
                  category: categoryCtrl.text.isNotEmpty ? categoryCtrl.text : null,
                );
                context.read<InventoryProvider>().addProduct(product);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
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
        title: Text('Restock \${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity Purchased'), keyboardType: TextInputType.number),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\${product.name} restocked successfully!')));
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

import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class UniversalSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters to search across all records...'));
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _performSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final res = results[index];
            return ListTile(
              leading: Icon(_getIconForType(res['type']), color: Colors.blueGrey),
              title: Text(res['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(res['subtitle']),
              trailing: Text(res['type'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Product': return Icons.inventory_2;
      case 'Customer Debt/Credit': return Icons.account_circle;
      case 'Mobile Money': return Icons.phone_android;
      case 'Expense': return Icons.receipt_long;
      case 'Stock Purchase': return Icons.local_shipping;
      default: return Icons.search;
    }
  }

  Future<List<Map<String, dynamic>>> _performSearch(String q) async {
    final db = await DatabaseHelper.instance.database;
    final searchTerm = '%\$q%';
    List<Map<String, dynamic>> consolidated = [];

    // Search Products (matches name, supplier, category, barcode)
    final products = await db.rawQuery(
      'SELECT name, price, quantity, category FROM products WHERE name LIKE ? OR supplier LIKE ? OR category LIKE ? OR barcode LIKE ?',
      [searchTerm, searchTerm, searchTerm, searchTerm]
    );
    for (var p in products) {
      consolidated.add({
        'type': 'Product',
        'title': p['name'],
        'subtitle': "Category: ${p['category'] ?? 'N/A'} | Price: \$${p['price']} | Stock: ${p['quantity']}"
      });
    }

    // Search Customers/Change Register (matches name, phone)
    final changeReg = await db.rawQuery(
      'SELECT customer_name, phone, amount_owed FROM change_register WHERE customer_name LIKE ? OR phone LIKE ?',
      [searchTerm, searchTerm]
    );
    for (var c in changeReg) {
      consolidated.add({
        'type': 'Customer Debt/Credit',
        'title': c['customer_name'] ?? 'Unknown',
        'subtitle': "Phone: ${c['phone'] ?? 'N/A'} | Amount: \$${c['amount_owed']}"
      });
    }

    // Search Mobile Money (matches name, phone, ecocash number, notes)
    final mobileMoney = await db.rawQuery(
      'SELECT type, customer_name, ecocash_number, amount FROM cash_operations WHERE customer_name LIKE ? OR phone LIKE ? OR ecocash_number LIKE ? OR notes LIKE ?',
      [searchTerm, searchTerm, searchTerm, searchTerm]
    );
    for (var m in mobileMoney) {
      consolidated.add({
        'type': 'Mobile Money',
        'title': "${m['type']} - \$${m['amount']}",
        'subtitle': "Customer: ${m['customer_name'] ?? 'N/A'} | EcoCash: ${m['ecocash_number']}"
      });
    }

    // Search Expenses (matches description)
    final expenses = await db.rawQuery(
      'SELECT description, amount, date FROM expenses WHERE description LIKE ?',
      [searchTerm]
    );
    for (var e in expenses) {
      consolidated.add({
        'type': 'Expense',
        'title': e['description'],
        'subtitle': "Amount: \$${e['amount']} | Date: ${e['date']}"
      });
    }

    // Search Stock Purchases (matches supplier)
    final stock = await db.rawQuery(
      'SELECT supplier, cost, quantity FROM stock_purchases WHERE supplier LIKE ?',
      [searchTerm]
    );
    for (var s in stock) {
      consolidated.add({
        'type': 'Stock Purchase',
        'title': "Restock from ${s['supplier']}",
        'subtitle': "Cost: \$${s['cost']} | Qty: ${s['quantity']}"
      });
    }

    return consolidated;
  }
}

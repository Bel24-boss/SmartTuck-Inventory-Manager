import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../providers/inventory_provider.dart';
import 'close_shop_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<String> _insightFuture;
  late Future<List<Map<String, dynamic>>> _topProductsFuture;

  @override
  void initState() {
    super.initState();
    _insightFuture = DatabaseHelper.instance.getDynamicInsight();
    _topProductsFuture = _getTopSellingProducts();
  }

  Future<List<Map<String, dynamic>>> _getTopSellingProducts() async {
    final db = await DatabaseHelper.instance.database;
    // Get all sale items and aggregate by product_id
    final saleItems = await db.query('sale_items');
    final products = await db.query('products');
    
    Map<int, int> salesCount = {};
    for (var item in saleItems) {
      final pid = item['product_id'] as int;
      final qty = item['quantity'] as int;
      salesCount[pid] = (salesCount[pid] ?? 0) + qty;
    }

    if (salesCount.isEmpty) return [];

    // Sort by most sold
    var sortedEntries = salesCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    List<Map<String, dynamic>> topProducts = [];
    for (var i = 0; i < sortedEntries.length && i < 5; i++) {
      final pid = sortedEntries[i].key;
      final qty = sortedEntries[i].value;
      final productMatch = products.firstWhere((p) => p['id'] == pid, orElse: () => {});
      final name = productMatch.isNotEmpty ? productMatch['name'] : 'Unknown';
      
      topProducts.add({
        'name': name.toString().length > 10 ? name.toString().substring(0, 10) : name,
        'quantity': qty
      });
    }
    
    return topProducts;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Operations Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseShopScreen())),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Close Shop (End of Day)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Total Sales', '\$1,240.50', Icons.stacked_line_chart, AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    return _buildSummaryCard('Total Products', '\${provider.products.length}', Icons.inventory_2, AppTheme.accentColor);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard('Expenses', '\$340.00', Icons.account_balance_wallet, Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'System Insights & Intelligence',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: _insightFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return Card(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.analytics_outlined, color: AppTheme.primaryColor, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Real-time Analytics Engine',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.data ?? 'Awaiting data...',
                              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Top Selling Products (Quantities Bought)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _topProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
              }
              final topProducts = snapshot.data ?? [];
              if (topProducts.isEmpty) {
                return const SizedBox(
                  height: 300, 
                  child: Card(child: Center(child: Text('No sales data yet to display graphs.')))
                );
              }

              // Find max Y for scaling
              double maxY = 10;
              for (var p in topProducts) {
                if (p['quantity'] > maxY) maxY = (p['quantity'] as int).toDouble() + 5;
              }

              return SizedBox(
                height: 300,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= topProducts.length) return const Text('');
                                return SideTitleWidget(
                                  meta: meta, 
                                  space: 4.0, 
                                  child: Text(topProducts[index]['name'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(topProducts.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: (topProducts[index]['quantity'] as int).toDouble(), 
                                color: AppTheme.primaryColor, 
                                width: 25, 
                                borderRadius: BorderRadius.circular(4)
                              )
                            ]
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
          ],
        ),
      ),
    );
  }
}

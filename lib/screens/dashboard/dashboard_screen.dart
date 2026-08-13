import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _revenue = 0.0;
  double _netProfit = 0.0;
  bool _isLoading = true;
  String _mlInsight = "Insufficient data to model insights. Awaiting minimum sales threshold to generate revenue optimization strategies.";

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    
    // Revenue
    final sales = await db.query('sales');
    double rev = 0.0;
    for (var s in sales) {
      rev += (s['total_amount'] as num).toDouble();
    }

    // Expenses
    final exps = await db.query('expenses');
    double expTotal = 0.0;
    for (var e in exps) {
      expTotal += (e['amount'] as num).toDouble();
    }

    // COGS
    final saleItems = await db.rawQuery('''
      SELECT si.quantity, p.buyingPrice 
      FROM sale_items si 
      JOIN products p ON si.product_id = p.id
    ''');
    
    double cogs = 0.0;
    for (var item in saleItems) {
      int qty = (item['quantity'] as num).toInt();
      double bp = (item['buyingPrice'] as num).toDouble();
      cogs += (qty * bp);
    }

    double netProfit = rev - cogs - expTotal;
    
    // Get insight string if sales exist
    String insight = _mlInsight;
    if (sales.length > 5) {
      insight = await DatabaseHelper.instance.getDynamicInsight();
    }

    if (mounted) {
      setState(() {
        _revenue = rev;
        _netProfit = netProfit;
        _mlInsight = insight;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick action FAB (e.g. quick sale)
        },
        backgroundColor: const Color(0xFF1CB581), // Vibrant green
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=800&q=80'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'SmartTuck Retail Hub',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.location_on, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Text('Local Community Store', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // System Insights Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_graph, color: Colors.black87),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('System Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                InkWell(
                                  onTap: _loadMetrics,
                                  child: Row(
                                    children: const [
                                      Icon(Icons.refresh, size: 14, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text('Refresh ML', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _mlInsight,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Metrics Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Real-Time Shop Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Updated Now', style: TextStyle(color: Colors.green[600], fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Revenue',
                      '\$${_revenue.toStringAsFixed(2)}',
                      'TOTAL SALES',
                      Icons.attach_money,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Net Profit',
                      '\$${_netProfit.toStringAsFixed(2)}',
                      'AFTER EXPENSES',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Advanced Modules
              const Text('Advanced Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insights, color: Colors.blue),
                  ),
                  title: const Text('Analytics & Reports', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('View detailed charts for best selling products and profits.', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Navigate to reports or change tab via provider in a real setup
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.black87),
                  ),
                  title: const Text('Expenses Manager', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Record rent, transport, salaries, and operating costs', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Navigate to expenses
                  },
                ),
              ),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }
}

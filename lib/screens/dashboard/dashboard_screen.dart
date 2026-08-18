import '../analytics/analytics_screen.dart';
import '../expenses/expenses_screen.dart';
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
  List<Map<String, dynamic>> _insights = [];
  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }


  Future<void> _loadMetrics() async {
    final db = await DatabaseHelper.instance.database;
    final sales = await db.query('sales');
    final expenses = await db.query('expenses');
    
    double rev = 0;
    for (var s in sales) { rev += s['total_amount'] as double; }
    
    double exp = 0;
    for (var e in expenses) { exp += e['amount'] as double; }
    
    final latest = await DatabaseHelper.instance.getLatestInsights();
    
    if (mounted) {
      setState(() {
        _revenue = rev;
        _netProfit = rev - exp;
        _insights = latest;
      });
    }
  }

  Future<void> _generateNewInsights() async {
    await DatabaseHelper.instance.generateAndSaveInsight();
    _loadMetrics();
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.auto_graph, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('System Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          InkWell(
                            onTap: _generateNewInsights,
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
                      const SizedBox(height: 16),
                      if (_insights.isEmpty)
                        const Text("No insights available. Tap 'Refresh ML' to generate.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      for (var insight in _insights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                insight['type'] == 'CRITICAL' ? Icons.warning_amber_rounded :
                                insight['type'] == 'TRENDING' ? Icons.trending_up : Icons.lightbulb_outline,
                                size: 18,
                                color: insight['type'] == 'CRITICAL' ? Colors.red :
                                insight['type'] == 'TRENDING' ? Colors.orange : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  insight['content'],
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                  },
                  borderRadius: BorderRadius.circular(16),
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
                    title: const Text('Advanced Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Real-time data visualization and fintech metrics', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                  ),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpensesScreen()));
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

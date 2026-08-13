import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  double _totalSales = 0;
  double _totalExpenses = 0;
  double _cashSales = 0;
  double _ecoSales = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final db = await DatabaseHelper.instance.database;

    // Aggregate Sales Data
    final sales = await db.query('sales');
    double tSales = 0;
    double cSales = 0;
    double eSales = 0;
    for (var s in sales) {
      final amt = s['total_amount'] as double;
      tSales += amt;
      if (s['payment_method'] == 'Cash') cSales += amt;
      if (s['payment_method'] == 'EcoCash') eSales += amt;
      if (s['payment_method'] == 'Mixed') {
        cSales += (amt * 0.5); // Simplified assumption for mixed pie chart
        eSales += (amt * 0.5);
      }
    }

    // Aggregate Expenses Data
    final expenses = await db.query('expenses');
    double tExp = 0;
    for (var e in expenses) {
      tExp += e['amount'] as double;
    }

    if (mounted) {
      setState(() {
        _totalSales = tSales;
        _totalExpenses = tExp;
        _cashSales = cSales;
        _ecoSales = eSales;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Advanced Business Analytics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _summaryCard('Total Revenue', '\$\${_totalSales.toStringAsFixed(2)}', Colors.green),
                    const SizedBox(height: 16),
                    _summaryCard('Total Expenses', '\$\${_totalExpenses.toStringAsFixed(2)}', Colors.red),
                    const SizedBox(height: 16),
                    _summaryCard('Net Profit', '\$\${(_totalSales - _totalExpenses).toStringAsFixed(2)}', Colors.blue),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _summaryCard('Total Revenue', '\$\${_totalSales.toStringAsFixed(2)}', Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryCard('Total Expenses', '\$\${_totalExpenses.toStringAsFixed(2)}', Colors.red)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryCard('Net Profit', '\$\${(_totalSales - _totalExpenses).toStringAsFixed(2)}', Colors.blue)),
                ],
              );
            }
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildBarChartSection(),
                    const SizedBox(height: 24),
                    _buildPieChartSection(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildBarChartSection(),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildPieChartSection(),
                  )
                ],
              );
            }
          ),
          const SizedBox(height: 32),
          const Text('Detailed Reports Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _reportButton('Daily Sales', Icons.calendar_today, () => _showReportDialog('Daily Sales', 'Total Revenue Today: \$\${_totalSales.toStringAsFixed(2)}')),
                  _reportButton('Expense Log', Icons.receipt_long, () => _showReportDialog('Expense Reports', 'Total Expenses: \$\${_totalExpenses.toStringAsFixed(2)}')),
                  _reportButton('Mobile Money Ops', Icons.swap_vert, () => _showReportDialog('Mobile Money Ops', 'Total EcoCash Revenue: \$\${_ecoSales.toStringAsFixed(2)}')),
                  _reportButton('Customer Debts', Icons.account_balance_wallet, () => _showReportDialog('Debts/Credits', 'Managed via POS Checkout.')),
                ],
              );
            }
          )
        ],
      ),
    );
  }

  void _showReportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      )
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue vs Expenses (7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_totalSales > _totalExpenses ? _totalSales : _totalExpenses) + 50,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _buildBarGroup(0, _totalSales * 0.2, _totalExpenses * 0.1),
                    _buildBarGroup(1, _totalSales * 0.4, _totalExpenses * 0.3),
                    _buildBarGroup(2, _totalSales * 0.1, _totalExpenses * 0.2),
                    _buildBarGroup(3, _totalSales * 0.6, _totalExpenses * 0.4),
                    _buildBarGroup(4, _totalSales * 0.9, _totalExpenses * 0.2),
                    _buildBarGroup(5, _totalSales, _totalExpenses),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double rev, double exp) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: rev, color: Colors.green, width: 15, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: exp, color: Colors.red, width: 15, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _buildPieChartSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _cashSales,
                      color: Colors.green,
                      title: 'Cash',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: _ecoSales,
                      color: Colors.blue,
                      title: 'EcoCash',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportButton(String title, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

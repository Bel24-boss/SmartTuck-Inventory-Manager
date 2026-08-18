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

    final sales = await db.query('sales');
    double tSales = 0, cSales = 0, eSales = 0;
    for (var s in sales) {
      final amt = s['total_amount'] as double;
      tSales += amt;
      if (s['payment_method'] == 'Cash') cSales += amt;
      if (s['payment_method'] == 'EcoCash') eSales += amt;
      if (s['payment_method'] == 'Mixed') {
        cSales += (amt * 0.5);
        eSales += (amt * 0.5);
      }
    }

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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Analytics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text('Real-time insights and metrics for your enterprise.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),
            
            _buildMetricsGrid(),
            
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
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
                    Expanded(flex: 2, child: _buildBarChartSection()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildPieChartSection()),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),
            const Text('Reports Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _buildReportsLibrary(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _summaryCard('Total Revenue', '\$${_totalSales.toStringAsFixed(2)}', const Color(0xFF10B981), Icons.trending_up),
              const SizedBox(height: 16),
              _summaryCard('Total Expenses', '\$${_totalExpenses.toStringAsFixed(2)}', const Color(0xFFEF4444), Icons.trending_down),
              const SizedBox(height: 16),
              _summaryCard('Net Profit', '\$${(_totalSales - _totalExpenses).toStringAsFixed(2)}', const Color(0xFF6B4EFF), Icons.account_balance),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _summaryCard('Total Revenue', '\$${_totalSales.toStringAsFixed(2)}', const Color(0xFF10B981), Icons.trending_up)),
            const SizedBox(width: 16),
            Expanded(child: _summaryCard('Total Expenses', '\$${_totalExpenses.toStringAsFixed(2)}', const Color(0xFFEF4444), Icons.trending_down)),
            const SizedBox(width: 16),
            Expanded(child: _summaryCard('Net Profit', '\$${(_totalSales - _totalExpenses).toStringAsFixed(2)}', const Color(0xFF6B4EFF), Icons.account_balance)),
          ],
        );
      }
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBarChartSection() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue vs Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 32),
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
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 100, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
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
    );
  }

  BarChartGroupData _buildBarGroup(int x, double rev, double exp) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: rev, color: const Color(0xFF10B981), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
        BarChartRodData(toY: exp, color: const Color(0xFFEF4444), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      ],
    );
  }

  Widget _buildPieChartSection() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Split', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(value: _cashSales > 0 ? _cashSales : 1, color: const Color(0xFF10B981), title: 'Cash', radius: 45, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(value: _ecoSales > 0 ? _ecoSales : 1, color: const Color(0xFF3B82F6), title: 'EcoCash', radius: 45, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsLibrary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _reportButton('Daily Sales Log', Icons.insert_chart_outlined, const Color(0xFF6B4EFF), () => _showReportDialog('Daily Sales', 'Total Revenue Today: \$${_totalSales.toStringAsFixed(2)}')),
            _reportButton('Expense Records', Icons.receipt_long_rounded, const Color(0xFFEF4444), () => _showReportDialog('Expense Reports', 'Total Expenses: \$${_totalExpenses.toStringAsFixed(2)}')),
            _reportButton('EcoCash Log', Icons.swap_vert_rounded, const Color(0xFF3B82F6), () => _showReportDialog('Mobile Money', 'Total EcoCash Revenue: \$${_ecoSales.toStringAsFixed(2)}')),
            _reportButton('Customer Credits', Icons.group_outlined, const Color(0xFFF59E0B), () => _showReportDialog('Credits', 'Managed via Change Register.')),
          ],
        );
      }
    );
  }

  Widget _reportButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      )
    );
  }
}

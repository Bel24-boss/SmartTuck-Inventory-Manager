import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'sales/pos_screen.dart';
import 'inventory/inventory_screen.dart';
import 'accounts/accounts_screen.dart';
import 'reports/reports_screen.dart';
import 'search/universal_search_delegate.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start background sync
    _runBackgroundSync();
  }

  void _runBackgroundSync() async {
    while (mounted) {
      await SyncService.syncAll();
      await Future.delayed(const Duration(seconds: 30)); // Sync every 30 seconds
    }
  }


  final List<Widget> _screens = [
    const DashboardScreen(),
    const PosScreen(),
    const InventoryScreen(),
    const AccountsScreen(),
    const ReportsScreen(),
    const Center(child: Text('Settings Coming Soon')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SmartTuck', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              showSearch(context: context, delegate: UniversalSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.point_of_sale, 'Sales', 1),
                _buildNavItem(Icons.inventory_2_outlined, 'Inventory', 2),
                _buildNavItem(Icons.account_balance_wallet_outlined, 'Accounts', 3),
                _buildNavItem(Icons.bar_chart, 'Reports', 4),
                _buildNavItem(Icons.settings_outlined, 'Settings', 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    final activeColor = const Color(0xFF6B4EFF); // Purple-blue from screenshot
    final inactiveColor = const Color(0xFF4A4A4A); // Dark grey from screenshot

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEBE5FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Slightly smaller for better fitting 6 items
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

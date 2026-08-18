import 'package:flutter/material.dart';
import '../services/sync_service.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_helper.dart';

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

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingChanges = 0;

  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    // Start background sync and listeners
    SyncService.listenToRemoteChanges('inventory');
    SyncService.listenToRemoteChanges('transactions');
    _runBackgroundSync();
  }


  


  void _runBackgroundSync() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async {
      if (mounted) {
        setState(() {
          _isOnline = !result.contains(ConnectivityResult.none);
        });
      }
      if (_isOnline) {
        setState(() => _isSyncing = true);
        try {
          await FirebaseFirestore.instance.waitForPendingWrites();
        } catch (_) {}
        if (mounted) setState(() => _isSyncing = false);
      }
    });
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
        title: const Text('SmartTuck Retail'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (!_isOnline) 
                   const Text('🔴 Offline (Pending Sync) ', style: TextStyle(color: Colors.red)),
                if (_isOnline && _isSyncing)
                   const Text('🟡 Syncing... ', style: TextStyle(color: Colors.orange)),
                if (_isOnline && !_isSyncing)
                   const Text('🟢 Synced ', style: TextStyle(color: Colors.green)),
              ],
            ),
          )
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

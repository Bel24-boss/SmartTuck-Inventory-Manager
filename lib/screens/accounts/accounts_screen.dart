import 'package:flutter/material.dart';
import '../expenses/expenses_screen.dart';
import '../change_register/change_register_screen.dart';
import 'cash_operations_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0, // Hide the appbar title area, only show tabs
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
              Tab(icon: Icon(Icons.phone_android), text: 'Mobile Money'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Change & Credit'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ExpensesScreen(),
            CashOperationsScreen(),
            ChangeRegisterScreen(),
          ],
        ),
      ),
    );
  }
}

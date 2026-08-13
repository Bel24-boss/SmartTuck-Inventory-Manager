import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';
import 'screens/opening_screen.dart';
import 'services/database_helper.dart';
import 'providers/inventory_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartTuckApp());
}

class SmartTuckApp extends StatelessWidget {
  const SmartTuckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'SmartTuck Inventory Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthScreen(),
      ),
    );
  }
}

class SessionRouter extends StatefulWidget {
  const SessionRouter({super.key});
  @override
  State<SessionRouter> createState() => _SessionRouterState();
}

class _SessionRouterState extends State<SessionRouter> {
  bool _isLoading = true;
  bool _hasActiveSession = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await DatabaseHelper.instance.getActiveSession();
    if (mounted) {
      setState(() {
        _hasActiveSession = session != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasActiveSession) {
      return const MainLayout();
    }
    return const OpeningScreen();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _passwordCtrl = TextEditingController();
  bool _isError = false;

  void _login() {
    if (_passwordCtrl.text.trim() == 'chenge26') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SessionRouter())
      );
    } else {
      setState(() {
        _isError = true;
      });
      _passwordCtrl.clear();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isError = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    const Text('Authentication Required', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text('Please enter the master password.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.key),
                        errorText: _isError ? 'Incorrect Password' : null,
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Unlock', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

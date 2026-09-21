import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/features/auth_flow.dart';
import 'package:flutter_application_inventory/features/dashboard_flow.dart';
import 'package:flutter_application_inventory/features/inventory_flow.dart';
import 'package:flutter_application_inventory/features/scanner_flow.dart';
import 'package:flutter_application_inventory/features/reports_flow.dart';
import 'package:flutter_application_inventory/features/profile_flow.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final MockService _mockService = MockService();
  bool _showSplash = true;
  bool _isAuthenticated = false;
  bool _isSigningUp = false;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mockService,
      builder: (context, child) {
        return MaterialApp(
          title: ' Warehouse Management',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          home: _buildCurrentScreen(),
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    if (_showSplash) {
      return SplashScreen(
        onFinish: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    if (!_isAuthenticated) {
      if (_isSigningUp) {
        return SignUpScreen(
          onSignUpSuccess: () {
            setState(() {
              _isAuthenticated = true;
              _isSigningUp = false;
            });
          },
          onGoToLogin: () {
            setState(() {
              _isSigningUp = false;
            });
          },
        );
      }
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
        onGoToSignUp: () {
          setState(() {
            _isSigningUp = true;
          });
        },
      );
    }

    return MainNavigationHub(
      service: _mockService,
      themeMode: _themeMode,
      onThemeToggle: _toggleTheme,
      onLogout: () {
        setState(() {
          _isAuthenticated = false;
        });
      },
    );
  }
}

class MainNavigationHub extends StatefulWidget {
  final MockService service;
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  const MainNavigationHub({
    super.key,
    required this.service,
    required this.themeMode,
    required this.onThemeToggle,
    required this.onLogout,
  });

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      DashboardScreen(
        service: widget.service,
        onNavigateToInventory: () => setState(() => _currentIndex = 1),
        onNavigateToScanner: () => setState(() => _currentIndex = 2),
        onNavigateToReports: () => setState(() => _currentIndex = 3),
        onNavigateToProfile: () => setState(() => _currentIndex = 4),
      ),
      InventoryScreen(service: widget.service),
      ScannerScreen(service: widget.service),
      ReportsScreen(service: widget.service),
      ProfileScreen(
        service: widget.service,
        onThemeChanged: widget.onThemeToggle,
      ),
    ];

    final isInventoryTab = _currentIndex == 1;
    final isDashboardTab = _currentIndex == 0;

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: "Inventory",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_outlined),
              label: "Scanner",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.picture_as_pdf_outlined),
              activeIcon: Icon(Icons.picture_as_pdf_rounded),
              label: "Reports",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              activeIcon: Icon(Icons.manage_accounts_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
      floatingActionButton: (isDashboardTab || isInventoryTab)
          ? FloatingActionButton(
              heroTag: "quick_add_fab",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductFormScreen(service: widget.service),
                  ),
                ).then((value) => setState(() {}));
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

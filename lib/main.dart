import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inventory_manager/screens/dashboard_screen.dart';
import 'package:inventory_manager/screens/equipment_list_screen.dart';
import 'package:inventory_manager/screens/reports_screen.dart';
import 'package:inventory_manager/screens/movement_history_screen.dart';
import 'package:inventory_manager/screens/settings_screen.dart';
import 'package:inventory_manager/database/database_init.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    initDatabase();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Инвентарный менеджер',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final bool _extendedNavigation = true;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const EquipmentListScreen(),
    const ReportsScreen(),
    const MovementHistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Боковая панель навигации
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: _extendedNavigation,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Главная'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.devices),
                label: Text('Оборудование'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assessment),
                label: Text('Отчеты'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text('История'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Настройки'),
              ),
            ],
          ),

          // Вертикальный разделитель
          const VerticalDivider(thickness: 1, width: 1),

          // Основной контент
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
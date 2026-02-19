import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Screens
import 'package:inventory_manager/screens/dashboard_screen.dart';
import 'package:inventory_manager/screens/equipment_list_screen.dart';
import 'package:inventory_manager/screens/reports_screen.dart';
import 'package:inventory_manager/screens/movement_history_screen.dart';
import 'package:inventory_manager/screens/settings_screen.dart';
import 'package:inventory_manager/screens/documents_screen.dart';
import 'package:inventory_manager/screens/consumables_list_screen.dart';
import 'package:inventory_manager/screens/employees_list_screen.dart';
import 'package:inventory_manager/database/database_init.dart';
import 'package:inventory_manager/services/logger_service.dart';

// Providers
import 'package:inventory_manager/providers/equipment_provider.dart';
import 'package:inventory_manager/providers/employee_provider.dart';
import 'package:inventory_manager/providers/consumable_provider.dart';
import 'package:inventory_manager/providers/movement_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    initDatabase();
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(LoggerService().logError(details.exception, details.stack));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(LoggerService().logError(error, stack));
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ConsumableProvider()),
        ChangeNotifierProvider(create: (_) => MovementProvider()),
      ],
      child: MaterialApp(
        title: 'Инвентарный менеджер',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ru', 'RU'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const MainNavigationScreen(),
      ),
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
  bool _extendedNavigation = true;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Главная',
    ),
    NavigationItem(
      icon: Icons.devices_outlined,
      selectedIcon: Icons.devices,
      label: 'Оборудование',
    ),
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Расходники',
    ),
    NavigationItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Сотрудники',
    ),
    NavigationItem(
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
      label: 'Отчеты',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: 'История',
    ),
    NavigationItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'Документы',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Настройки',
    ),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const EquipmentListScreen(),
      const ConsumablesListScreen(),
      const EmployeesListScreen(),
      const ReportsScreen(),
      const MovementHistoryScreen(),
      const DocumentsScreen(),
      const SettingsScreen(),
    ];
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    context.read<EquipmentProvider>().loadEquipment();
    context.read<EmployeeProvider>().loadEmployees();
    context.read<ConsumableProvider>().loadConsumables();
    context.read<MovementProvider>().loadMovements();
  }

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
            minExtendedWidth: 180,
            destinations: _navigationItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              );
            }).toList(),
            leading: _extendedNavigation
                ? SizedBox(
                    width: 180,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.business,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Инвентарь',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.business,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
            trailing: _extendedNavigation
                ? IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _extendedNavigation = false;
                      });
                    },
                    tooltip: 'Свернуть',
                  )
                : IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _extendedNavigation = true;
                      });
                    },
                    tooltip: 'Развернуть',
                  ),
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

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

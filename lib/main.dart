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
import 'package:inventory_manager/screens/login_screen.dart';
import 'package:inventory_manager/screens/analytics_screen.dart';
import 'package:inventory_manager/screens/rooms_screen.dart';
import 'package:inventory_manager/screens/vehicles_screen.dart';
import 'package:inventory_manager/screens/keys_screen.dart';
import 'package:inventory_manager/screens/telephony_screen.dart';
import 'package:inventory_manager/screens/audit_log_screen.dart';
import 'package:inventory_manager/screens/users_screen.dart';

// Database
import 'package:inventory_manager/database/database_init.dart';
import 'package:inventory_manager/services/logger_service.dart';

// Providers
import 'package:inventory_manager/providers/equipment_provider.dart';
import 'package:inventory_manager/providers/employee_provider.dart';
import 'package:inventory_manager/providers/consumable_provider.dart';
import 'package:inventory_manager/providers/movement_provider.dart';
import 'package:inventory_manager/providers/auth_provider.dart';
import 'package:inventory_manager/providers/settings_provider.dart';
import 'package:inventory_manager/providers/maintenance_provider.dart';
import 'package:inventory_manager/providers/analytics_provider.dart';
import 'package:inventory_manager/providers/sync_provider.dart';

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
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ConsumableProvider()),
        ChangeNotifierProvider(create: (_) => MovementProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          return MaterialApp(
            title: 'Инвентарный менеджер',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ru', 'RU'),
              Locale('en', 'US'),
            ],
            locale: Locale(settings.language.code),
            theme: settings.getLightTheme(),
            darkTheme: settings.getDarkTheme(),
            themeMode: settings.themeMode,
            initialRoute: settings.requireLogin && !auth.isAuthenticated ? '/login' : '/home',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainNavigationScreen(),
            },
          );
        },
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();
    
    // Load settings
    await settings.loadSettings();
    
    // Start auto sync if enabled
    if (settings.appSettings.autoSync) {
      sync.startAutoSync(intervalMinutes: settings.appSettings.syncInterval);
    }

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
    context.read<MaintenanceProvider>().loadMaintenanceRecords();
    context.read<AnalyticsProvider>().loadAllStats();
    context.read<SyncProvider>().loadPendingItems();
  }

  List<NavigationRailDestination> _getDestinations(SettingsProvider settings) {
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Главная'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.devices_outlined),
        selectedIcon: Icon(Icons.devices),
        label: Text('Оборудование'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('Расходники'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Сотрудники'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('Аналитика'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: Text('Отчеты'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: Text('История'),
      ),
    ];

    // Optional destinations based on settings
    if (settings.enableMaintenance) {
      destinations.add(const NavigationRailDestination(
        icon: Icon(Icons.build_outlined),
        selectedIcon: Icon(Icons.build),
        label: Text('Обслуживание'),
      ));
    }

    destinations.add(const NavigationRailDestination(
      icon: Icon(Icons.room_preferences_outlined),
      selectedIcon: Icon(Icons.room_preferences),
      label: Text('Помещения'),
    ));

    if (settings.enableKeyManagement) {
      destinations.add(const NavigationRailDestination(
        icon: Icon(Icons.vpn_key_outlined),
        selectedIcon: Icon(Icons.vpn_key),
        label: Text('Ключи'),
      ));
    }

    if (settings.enableTelephony) {
      destinations.add(const NavigationRailDestination(
        icon: Icon(Icons.phone_outlined),
        selectedIcon: Icon(Icons.phone),
        label: Text('Телефония'),
      ));
    }

    if (settings.enableVehicleTracking) {
      destinations.add(const NavigationRailDestination(
        icon: Icon(Icons.directions_car_outlined),
        selectedIcon: Icon(Icons.directions_car),
        label: Text('Транспорт'),
      ));
    }

    destinations.addAll([
      const NavigationRailDestination(
        icon: Icon(Icons.description_outlined),
        selectedIcon: Icon(Icons.description),
        label: Text('Документы'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Настройки'),
      ),
    ]);

    return destinations;
  }

  List<Widget> _getScreens(SettingsProvider settings, AuthProvider auth) {
    final screens = <Widget>[
      const DashboardScreen(),
      const EquipmentListScreen(),
      const ConsumablesListScreen(),
      const EmployeesListScreen(),
      const AnalyticsScreen(),
      const ReportsScreen(),
      const MovementHistoryScreen(),
    ];

    if (settings.enableMaintenance) {
      screens.add(const Scaffold(
        body: Center(child: Text('Обслуживание - в разработке')),
      ));
    }

    screens.add(const RoomsScreen());

    if (settings.enableKeyManagement) {
      screens.add(const KeysScreen());
    }

    if (settings.enableTelephony) {
      screens.add(const TelephonyScreen());
    }

    if (settings.enableVehicleTracking) {
      screens.add(const VehiclesScreen());
    }

    screens.addAll([
      const DocumentsScreen(),
      const SettingsScreen(),
    ]);

    return screens;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final destinations = _getDestinations(settings);
    final screens = _getScreens(settings, auth);

    // Ensure selected index is valid
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          // Side navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            extended: _extendedNavigation && MediaQuery.of(context).size.width > 800,
            minExtendedWidth: 200,
            destinations: destinations,
            leading: _buildLeadingHeader(),
            trailing: _buildTrailingControls(auth),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Main content
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingHeader() {
    final isExtended = _extendedNavigation && MediaQuery.of(context).size.width > 800;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isExtended
          ? Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Инвентарь',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Icon(
              Icons.business,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
    );
  }

  Widget _buildTrailingControls(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sync indicator
        Consumer<SyncProvider>(
          builder: (context, sync, _) {
            if (sync.pendingCount == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Tooltip(
                message: '${sync.pendingCount} ожидает синхронизации',
                child: Badge(
                  label: Text('${sync.pendingCount}'),
                  child: IconButton(
                    icon: Icon(
                      sync.isSyncing ? Icons.sync : Icons.sync_outlined,
                      color: sync.isOnline ? null : Colors.grey,
                    ),
                    onPressed: sync.isSyncing ? null : () => sync.sync(),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Expand/collapse
        IconButton(
          icon: Icon(_extendedNavigation ? Icons.chevron_left : Icons.chevron_right),
          onPressed: () => setState(() => _extendedNavigation = !_extendedNavigation),
          tooltip: _extendedNavigation ? 'Свернуть' : 'Развернуть',
        ),
        
        const SizedBox(height: 8),
        
        // User menu
        if (auth.isAuthenticated)
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                auth.currentUser!.username.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // Navigate to profile
                  break;
                case 'audit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                  );
                  break;
                case 'users':
                  if (auth.isAdmin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersScreen()),
                    );
                  }
                  break;
                case 'logout':
                  auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  auth.currentUser?.username ?? 'Пользователь',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Профиль'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'audit',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Журнал действий'),
                  ],
                ),
              ),
              if (auth.isAdmin)
                const PopupMenuItem(
                  value: 'users',
                  child: Row(
                    children: [
                      Icon(Icons.manage_accounts),
                      SizedBox(width: 8),
                      Text('Пользователи'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Выйти', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

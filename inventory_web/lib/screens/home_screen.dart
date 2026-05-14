import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/consumable_provider.dart';
import '../providers/employee_provider.dart';
import 'equipment_list_screen.dart';
import 'consumables_list_screen.dart';
import 'employees_list_screen.dart';
import 'locations_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    EquipmentListScreen(),
    ConsumablesListScreen(),
    EmployeesListScreen(),
    LocationsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Manager'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    Text(
                      auth.currentUser?.fullName ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Выйти',
                      onPressed: () async {
                        await auth.logout();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: FloatingActionButton(
              heroTag: 'add_btn',
              onPressed: () {
                // Кнопка добавления в зависимости от экрана
                _showAddDialog();
              },
              child: const Icon(Icons.add),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Обзор'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.devices_outlined),
                selectedIcon: Icon(Icons.devices),
                label: Text('Оборудование'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Расходники'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('Сотрудники'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.location_on_outlined),
                selectedIcon: Icon(Icons.location_on),
                label: Text('Локации'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    switch (_selectedIndex) {
      case 1:
        _navigateToEquipmentAdd();
        break;
      case 2:
        _navigateToConsumableAdd();
        break;
      case 3:
        _navigateToEmployeeAdd();
        break;
      case 4:
        _navigateToLocationAdd();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите раздел для добавления')),
        );
    }
  }

  void _navigateToEquipmentAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEquipmentScreen()),
    );
  }

  void _navigateToConsumableAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddConsumableScreen()),
    );
  }

  void _navigateToEmployeeAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
    );
  }

  void _navigateToLocationAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLocationScreen()),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Обзор',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Consumer3<EquipmentProvider, ConsumableProvider, EmployeeProvider>(
            builder: (context, eq, cons, emp, _) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2,
                children: [
                  _buildStatCard(
                    context,
                    'Оборудование',
                    eq.equipment.length.toString(),
                    Icons.devices,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    'Доступно',
                    eq.availableEquipment.length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    context,
                    'Расходники',
                    cons.consumables.length.toString(),
                    Icons.inventory_2,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    'Сотрудники',
                    emp.employees.length.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Быстрые действия',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => _navigateToEquipmentAdd(),
                icon: const Icon(Icons.add),
                label: const Text('Добавить оборудование'),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToConsumableAdd(),
                icon: const Icon(Icons.add),
                label: const Text('Добавить расходник'),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToEmployeeAdd(),
                icon: const Icon(Icons.person_add),
                label: const Text('Добавить сотрудника'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEquipmentAdd() {
    // Навигация будет через родителя
  }

  void _navigateToConsumableAdd() {}
  void _navigateToEmployeeAdd() {}
}

// Placeholder screens for navigation
class AddEquipmentScreen extends StatelessWidget {
  const AddEquipmentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить оборудование')),
      body: const Center(child: Text('Форма добавления оборудования')),
    );
  }
}

class AddConsumableScreen extends StatelessWidget {
  const AddConsumableScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить расходник')),
      body: const Center(child: Text('Форма добавления расходника')),
    );
  }
}

class AddEmployeeScreen extends StatelessWidget {
  const AddEmployeeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить сотрудника')),
      body: const Center(child: Text('Форма добавления сотрудника')),
    );
  }
}

class AddLocationScreen extends StatelessWidget {
  const AddLocationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить локацию')),
      body: const Center(child: Text('Форма добавления локации')),
    );
  }
}

import 'user.dart';

/// Права доступа пользователя
enum Permission {
  // Оборудование
  viewEquipment('Просмотр оборудования'),
  createEquipment('Создание оборудования'),
  editEquipment('Редактирование оборудования'),
  deleteEquipment('Удаление оборудования'),
  
  // Расходники
  viewConsumables('Просмотр расходников'),
  createConsumable('Создание расходников'),
  editConsumable('Редактирование расходников'),
  deleteConsumable('Удаление расходников'),
  
  // Сотрудники
  viewEmployees('Просмотр сотрудников'),
  createEmployee('Создание сотрудников'),
  editEmployee('Редактирование сотрудников'),
  deleteEmployee('Удаление сотрудников'),
  
  // Задачи
  viewTasks('Просмотр задач'),
  createTask('Создание задач'),
  editTask('Редактирование задач'),
  deleteTask('Удаление задач'),
  assignTask('Назначение задач'),
  
  // Отчеты
  viewReports('Просмотр отчетов'),
  exportReports('Экспорт отчетов'),
  
  // Настройки
  viewSettings('Просмотр настроек'),
  editSettings('Редактирование настроек'),
  
  // Пользователи
  viewUsers('Просмотр пользователей'),
  createUser('Создание пользователей'),
  editUser('Редактирование пользователей'),
  deleteUser('Удаление пользователей'),
  editUserPermissions('Изменение прав пользователей'),

  // Кинотеатр / Касса
  viewCinema('Просмотр кинотеатра'),
  manageEvents('Управление мероприятиями'),
  manageScreenings('Управление сеансами'),
  sellTickets('Продажа билетов'),
  returnTickets('Возврат билетов'),
  manageCinemaHalls('Управление залами'),
  viewCashierReport('Просмотр отчётов кассира');

  final String label;
  const Permission(this.label);
}

/// Предустановленные роли с правами
enum Role {
  admin,      // Полный доступ
  manager,    // Управление оборудованием и задачами
  employee,   // Базовый доступ
  viewer,     // Только просмотр
  cashier;    // Кассир (продажа билетов)

  List<Permission> get permissions {
    switch (this) {
      case admin:
        return Permission.values;

      case manager:
        return [
          // Оборудование
          Permission.viewEquipment,
          Permission.createEquipment,
          Permission.editEquipment,
          Permission.deleteEquipment,
          // Расходники
          Permission.viewConsumables,
          Permission.createConsumable,
          Permission.editConsumable,
          Permission.deleteConsumable,
          // Сотрудники
          Permission.viewEmployees,
          // Задачи
          Permission.viewTasks,
          Permission.createTask,
          Permission.editTask,
          Permission.deleteTask,
          Permission.assignTask,
          // Отчеты
          Permission.viewReports,
          Permission.exportReports,
          // Настройки
          Permission.viewSettings,
          // Пользователи
          Permission.viewUsers,
          // Кинотеатр
          Permission.viewCinema,
          Permission.manageEvents,
          Permission.manageScreenings,
          Permission.manageCinemaHalls,
        ];

      case employee:
        return [
          // Оборудование
          Permission.viewEquipment,
          // Расходники
          Permission.viewConsumables,
          // Сотрудники
          Permission.viewEmployees,
          // Задачи
          Permission.viewTasks,
          Permission.editTask,
          // Отчеты
          Permission.viewReports,
          // Настройки
          Permission.viewSettings,
        ];

      case viewer:
        return [
          Permission.viewEquipment,
          Permission.viewConsumables,
          Permission.viewEmployees,
          Permission.viewTasks,
          Permission.viewReports,
          Permission.viewSettings,
        ];

      case cashier:
        return [
          // Кинотеатр / Касса
          Permission.viewCinema,
          Permission.sellTickets,
          Permission.returnTickets,
          Permission.viewCashierReport,
          // Просмотр мероприятий и сеансов
          Permission.manageEvents,
          Permission.manageScreenings,
        ];
    }
  }
}

/// Расширения для проверки прав
extension PermissionCheck on List<Permission> {
  bool has(Permission permission) => contains(permission);

  bool hasAll(List<Permission> permissions) {
    return permissions.every((p) => contains(p));
  }

  bool hasAny(List<Permission> permissions) {
    return permissions.any((p) => contains(p));
  }
}

/// Extension methods для удобной проверки прав пользователя
extension UserPermissions on User {
  // Задачи
  bool get canViewTasks => hasPermission(Permission.viewTasks);
  bool get canCreateTask => hasPermission(Permission.createTask);
  bool get canEditTask => hasPermission(Permission.editTask);
  bool get canDeleteTask => hasPermission(Permission.deleteTask);
  bool get canAssignTask => hasPermission(Permission.assignTask);
  
  // Оборудование
  bool get canViewEquipment => hasPermission(Permission.viewEquipment);
  bool get canCreateEquipment => hasPermission(Permission.createEquipment);
  bool get canEditEquipment => hasPermission(Permission.editEquipment);
  bool get canDeleteEquipment => hasPermission(Permission.deleteEquipment);
  
  // Расходники
  bool get canViewConsumables => hasPermission(Permission.viewConsumables);
  bool get canCreateConsumable => hasPermission(Permission.createConsumable);
  bool get canEditConsumable => hasPermission(Permission.editConsumable);
  bool get canDeleteConsumable => hasPermission(Permission.deleteConsumable);
  
  // Сотрудники
  bool get canViewEmployees => hasPermission(Permission.viewEmployees);
  bool get canCreateEmployee => hasPermission(Permission.createEmployee);
  bool get canEditEmployee => hasPermission(Permission.editEmployee);
  bool get canDeleteEmployee => hasPermission(Permission.deleteEmployee);
  
  // Отчеты
  bool get canViewReports => hasPermission(Permission.viewReports);
  bool get canExportReports => hasPermission(Permission.exportReports);
  
  // Настройки
  bool get canViewSettings => hasPermission(Permission.viewSettings);
  bool get canEditSettings => hasPermission(Permission.editSettings);
  
  // Пользователи
  bool get canViewUsers => hasPermission(Permission.viewUsers);
  bool get canCreateUser => hasPermission(Permission.createUser);
  bool get canEditUser => hasPermission(Permission.editUser);
  bool get canDeleteUser => hasPermission(Permission.deleteUser);
  bool get canEditUserPermissions => hasPermission(Permission.editUserPermissions);

  // Кинотеатр / Касса
  bool get canViewCinema => hasPermission(Permission.viewCinema);
  bool get canManageEvents => hasPermission(Permission.manageEvents);
  bool get canManageScreenings => hasPermission(Permission.manageScreenings);
  bool get canSellTickets => hasPermission(Permission.sellTickets);
  bool get canReturnTickets => hasPermission(Permission.returnTickets);
  bool get canManageCinemaHalls => hasPermission(Permission.manageCinemaHalls);
  bool get canViewCashierReport => hasPermission(Permission.viewCashierReport);

  bool get isCashier => role == UserRole.cashier || role == UserRole.admin;
}

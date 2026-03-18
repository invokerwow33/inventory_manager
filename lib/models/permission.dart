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
  editUserPermissions('Изменение прав пользователей');

  final String label;
  const Permission(this.label);
}

/// Предустановленные роли с правами
enum Role {
  admin,      // Полный доступ
  manager,    // Управление оборудованием и задачами
  employee,   // Базовый доступ
  viewer;     // Только просмотр

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

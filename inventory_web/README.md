# Inventory Manager Web

Система управления инвентарем - Web версия на Flutter.

## Возможности

- ✅ Авторизация пользователей (admin/admin123 по умолчанию)
- ✅ Управление оборудованием (добавление, просмотр, выдача, перемещение)
- ✅ Управление расходниками
- ✅ Управление сотрудниками
- ✅ Управление локациями
- ✅ Сохранение данных в браузере (LocalStorage)
- ✅ Адаптивный интерфейс для десктопа и мобильных устройств

## Запуск проекта

### 1. Установка зависимостей
```bash
cd inventory_web
flutter pub get
```

### 2. Запуск для Web
```bash
flutter run -d chrome
```

Или для запуска на любом устройстве:
```bash
flutter run
```

### 3. Сборка для production
```bash
flutter build web --release
```

## Структура проекта

```
inventory_web/
├── lib/
│   ├── main.dart                 # Точка входа
│   ├── models/                   # Модели данных
│   │   ├── user.dart
│   │   ├── equipment.dart
│   │   ├── consumable.dart
│   │   ├── employee.dart
│   │   └── location.dart
│   ├── providers/                # State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── equipment_provider.dart
│   │   ├── consumable_provider.dart
│   │   ├── employee_provider.dart
│   │   └── location_provider.dart
│   ├── screens/                  # UI экраны
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   └── ...
│   ├── services/                 # Сервисы
│   │   └── storage_service.dart  # LocalStorage для Web
│   └── utils/                    # Утилиты
└── pubspec.yaml
```

## Данные по умолчанию

При первом запуске создается пользователь:
- **Логин:** admin
- **Пароль:** admin123

## Хранение данных

Данные сохраняются в LocalStorage браузера через пакет `shared_preferences`. 
Для сброса данных очистите кэш браузера или используйте DevTools.

## Технологии

- Flutter 3.x
- Provider (state management)
- SharedPreferences (localStorage)
- UUID (генерация идентификаторов)
- Material Design 3

## Примечания

- Web версия не требует базы данных
- Все данные хранятся локально в браузере
- Для production рекомендуется добавить бэкенд API

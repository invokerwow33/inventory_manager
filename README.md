# Инвентарный Менеджер (Inventory Manager)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Web%20%7C%20Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev)

**Инвентарный Менеджер** — это кроссплатформенное Flutter-приложение для комплексного управления инвентарем, оборудованием, расходными материалами и сотрудниками предприятия.

---

## 📋 Возможности

### 🖥️ Управление оборудованием
- ✅ Полный CRUD (создание, чтение, обновление, удаление)
- ✅ QR-коды и штрих-коды (генерация и сканирование)
- ✅ Отслеживание статуса (в использовании, на складе, в ремонте, списано)
- ✅ Привязка к сотрудникам и помещениям
- ✅ Фотоматериалы оборудования
- ✅ Геолокация
- ✅ История перемещений
- ✅ Амортизация и текущая стоимость

### 📦 Расходные материалы
- ✅ Учет количества и категорий
- ✅ Минимальные остатки с уведомлениями
- ✅ Приход/расход/перемещение
- ✅ Поставщики и единицы измерения
- ✅ История операций

### 👥 Сотрудники
- ✅ База сотрудников с контактами
- ✅ Привязка оборудования
- ✅ Статус (в отпуске, уволен, активен)
- ✅ История выдачи оборудования
- ✅ Должности и отделы

### 📊 Аналитика и отчеты
- ✅ Графики и диаграммы (fl_chart)
- ✅ Статистика по оборудованию и расходникам
- ✅ Экспорт в CSV и Excel
- ✅ Печать документов (PDF)
- ✅ Журнал перемещений
- ✅ Журнал аудита действий

### 🔄 Синхронизация
- ✅ Офлайн-режим работы
- ✅ Автоматическая синхронизация при подключении
- ✅ Очередь изменений
- ✅ Индикатор состояния синхронизации

### 🔐 Безопасность
- ✅ Система пользователей с авторизацией
- ✅ Хеширование паролей (bcrypt)
- ✅ Журнал аудита всех действий
- ✅ Разграничение прав доступа

### 📱 Дополнительные модули
- ✅ Помещения (кабинеты, склады)
- ✅ Ключи (учет выдачи ключей)
- ✅ Транспорт (служебные автомобили)
- ✅ Телефония (учет телефонов и SIM-карт)
- ✅ Обслуживание (плановое ТО)
- ✅ Документы (акты, накладные)

### 🎨 Интерфейс
- ✅ Material Design 3
- ✅ Темная и светлая темы
- ✅ Мультиязычность (русский/английский)
- ✅ Адаптивный дизайн для всех платформ
- ✅ Навигационная панель с быстрым доступом

---

## 🚀 Быстрый старт

### Требования
- **Flutter SDK** >= 3.0.0
- **Dart** >= 3.0.0
- **Windows 10/11** (для Desktop)
- **Android Studio** / **Xcode** (для Mobile)

### Установка

```bash
# Клонировать репозиторий
git clone <repository-url>
cd inventory_manager

# Получить зависимости
flutter pub get

# Запустить приложение
flutter run

# Для Windows
flutter run -d windows

# Для Web
flutter run -d chrome

# Для Android
flutter run -d android
```

### Сборка релизной версии

```bash
# Windows
flutter build windows

# Web
flutter build web

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 🏗️ Архитектура

```
lib/
├── database/           # Слой доступа к данным
│   ├── migrations/     # Миграции БД (V2-V5)
│   ├── database_helper_sqlite.dart   # SQLite (Desktop/Mobile)
│   ├── simple_database_helper.dart   # JSON (Web)
│   └── database_init.dart            # Инициализация
├── models/             # Модели данных (17 моделей)
├── providers/          # State management (Provider)
├── screens/            # UI экраны (33 экрана)
├── services/           # Бизнес-логика и сервисы
├── utils/              # Утилиты и константы
├── widgets/            # Переиспользуемые компоненты
└── main.dart           # Точка входа
```

### Технологический стек

| Категория | Пакеты |
|-----------|--------|
| **State Management** | provider |
| **Базы данных** | sqflite, sqflite_common_ffi, postgres, mysql1 |
| **HTTP/Сеть** | dio, connectivity_plus, shelf |
| **UI/Визуализация** | fl_chart, qr_flutter, barcode_widget |
| **Сканеры** | mobile_scanner |
| **Файлы** | file_picker, path_provider, excel, csv |
| **Печать** | printing, pdf |
| **Безопасность** | bcrypt, crypto, encrypt |
| **Изображения** | image_picker, cached_network_image |
| **Хранение** | shared_preferences |
| **Уведомления** | flutter_local_notifications |
| **Google** | googleapis, google_sign_in |

---

## 📁 Структура базы данных

### Основные таблицы
- `equipment` - Оборудование
- `employees` - Сотрудники
- `consumables` - Расходные материалы
- `movements` - Перемещения оборудования
- `consumable_movements` - Операции с расходниками

### Дополнительные таблицы
- `sync_queue` - Очередь синхронизации
- `users` - Пользователи системы
- `audit_logs` - Журнал аудита
- `rooms` - Помещения
- `room_equipment` - Связь помещений с оборудованием
- `vehicles` - Транспортные средства
- `keys` - Ключи
- `telephony` - Телефония
- `maintenance` - Обслуживание
- `app_settings` - Настройки приложения

### Миграции
- **V2**: Добавление barcode и qr_code в equipment
- **V3**: Добавление geolocation в equipment
- **V4**: Создание таблицы sync_queue
- **V5**: Создание таблицы room_equipment

---

## 🧪 Тестирование

```bash
# Запустить все тесты
flutter test

# Запустить тесты БД
flutter test test/database/

# Запустить тесты моделей
flutter test test/models/

# Запустить тесты провайдеров
flutter test test/providers/

# Проверка кода
flutter analyze
```

### Покрытие тестами
- ✅ Операции базы данных (18 тестов)
- ✅ Модели (Equipment, Employee, Consumable)
- ✅ Провайдеры (EquipmentProvider)
- ✅ Валидаторы и утилиты

---

## 📖 Документация

### Основные файлы документации
- [`FIXES_SUMMARY.md`](FIXES_SUMMARY.md) - История исправлений ошибок
- [`REMAINING_FIXES_SUMMARY.md`](REMAINING_FIXES_SUMMARY.md) - Последние исправления
- [`WINDOWS_BUILD.md`](WINDOWS_BUILD.md) - Сборка для Windows

### Известные ограничения
1. **Web-аутентификация** - не полностью реализована (используется SimpleDatabaseHelper с JSON)
2. **Продвинутые функции на Web** - аудит, обслуживание, помещения требуют полной реализации
3. **Синхронизация** - требует настройки серверного бэкенда (укажите ваш URL в `sync_service.dart`)

---

## 🔧 Настройка

### Первый запуск
При первом запуске приложение создаст базу данных в директории:
- **Windows**: `%APPDATA%/inventory_manager/inventory.db`
- **Web**: IndexedBrowser (JSON хранилище)
- **Android**: `/data/data/<package>/databases/inventory.db`
- **iOS**: `Documents/inventory.db`

### Настройка синхронизации
Откройте `lib/services/sync_service.dart` и укажите URL вашего сервера:

```dart
static const String _baseUrl = 'http://your-server.com/api';
```

### Настройка логирования
Логирование включено по умолчанию. Логи сохраняются в:
- **Desktop**: `logs/inventory_manager.log`

---

## 🎯 Планы развития

- [ ] Реализация полноценной веб-аутентификации
- [ ] Серверный бэкенд для синхронизации
- [ ] CI/CD пайплайн
- [ ] E2E тесты
- [ ] Push-уведомления
- [ ] Интеграция с 1С
- [ ] REST API для мобильного доступа
- [ ] Docker-контейнер для сервера синхронизации

---

## 🤝 Вклад в проект

1. Создайте форк репозитория
2. Создайте ветку для вашей функции (`git checkout -b feature/amazing-feature`)
3. Закоммитьте изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

### Стиль кода
- Следуйте [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Используйте `flutter analyze` перед коммитом
- Добавляйте тесты для нового функционала
- Документируйте публичные API

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробнее см. в файле [LICENSE](LICENSE).

---

## 👥 Авторы

- **Разработка** - Inventory Manager Team
- **Вкладчики** - См. [Contributors](../../contributors)

---

## 📞 Поддержка

Если у вас возникли вопросы или проблемы:
1. Проверьте существующие [Issues](../../issues)
2. Создайте новый [Issue](../../issues/new) с подробным описанием
3. Для срочных вопросов свяжитесь с командой поддержки

---

## 🙏 Благодарности

- [Flutter](https://flutter.dev) - Кроссплатформенный фреймворк
- [Dart](https://dart.dev) - Язык программирования
- Все пакеты с [pub.dev](https://pub.dev)

---

*Последнее обновление: Март 2026*

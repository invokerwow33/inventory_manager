# Windows Build Support

This document describes the Windows desktop support that has been added to the inventory_manager application.

## What Was Added

### 1. Windows Platform Files
- Complete Windows runner application with CMake build configuration
- Located in `windows/` directory
- Includes native Windows window management and Flutter embedding

### 2. Database Initialization for Windows
- Added `sqflite_common_ffi` initialization in `lib/main.dart`
- Database helper properly configured for desktop platforms (Windows/Linux/macOS)
- Conditional initialization only runs on desktop platforms

### 3. Unified Database Helper
- Consolidated database helper into `lib/database/database_helper_sqlite.dart`
- Removed duplicate and circular dependencies
- Clean conditional exports for web vs desktop platforms

## Building on Windows

### Prerequisites
- Flutter SDK 3.0 or higher
- Visual Studio 2022 with "Desktop development with C++" workload
- Windows 10 or higher

### Build Commands

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d windows

# Build release version
flutter build windows

# The executable will be in: build/windows/runner/Release/
```

## Key Files Modified

- `lib/main.dart` - Added Windows/desktop database initialization
- `lib/database/database_helper.dart` - Platform-conditional exports
- `lib/database/database_helper_sqlite.dart` - SQLite implementation for desktop
- `lib/database/database_init.dart` - sqflite_common_ffi initialization

## Architecture

The application now uses a platform-aware database strategy:

- **Desktop (Windows/Linux/macOS)**: Uses SQLite via `sqflite_common_ffi`
- **Web**: Uses SimpleDatabaseHelper with JSON file storage
- **Mobile (Android/iOS)**: Uses standard `sqflite`

All platforms share the same `DatabaseHelper` interface through conditional exports.

## Testing

To verify the Windows build works:

```bash
# Check for any analysis issues
flutter analyze

# Run tests
flutter test

# Launch the app
flutter run -d windows
```

## Known Issues

- Some screens still reference the old database helper path (being fixed)
- Test file needs to be updated with correct package name

## Future Improvements

- Add Windows-specific features (e.g., system tray integration)
- Optimize database performance for desktop
- Add Windows installer configuration

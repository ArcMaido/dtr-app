# DTR App - Flutter Development Guidelines

## Project Overview

DTR App is a Flutter mobile application for tracking daily work hours and time records on Android and iOS platforms.

## Project Structure

- **lib/**: Main application code
  - `main.dart`: Application entry point and theme setup
  - `screens/`: User interface screens (Home, Calendar, Export)
  - `models/`: Data models (TimeRecord)
  - `services/`: Business logic (Database, Export)
  - `widgets/`: Reusable widgets
  - `utils/`: Utility functions and helpers

- **pubspec.yaml**: Project dependencies and configuration

## Development Setup

1. Ensure Flutter SDK 3.0.0 or higher is installed
2. Run `flutter pub get` to install dependencies
3. Connect a device or start an emulator
4. Run `flutter run` to launch the app

## Key Technologies

- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language
- **SQLite**: Local database via sqflite
- **Material Design 3**: UI framework

## Coding Standards

- Follow Dart style guide (dart.dev/guides/language/effective-dart)
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent indentation (2 spaces)

## Building for Release

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Features Implementation Checklist

- [x] Daily time in/out recording
- [x] Calendar view with monthly overview
- [x] Note taking for daily entries
- [x] CSV and JSON export
- [x] Local SQLite storage
- [x] Bottom navigation
- [x] Date range filtering

## Testing Recommendations

- Test on both Android and iOS devices
- Verify database CRUD operations
- Test export functionality
- Validate date range calculations
- Check timezone handling

## Common Issues and Solutions

**App won't run:**
- Run `flutter clean` and `flutter pub get`
- Check Flutter/Dart SDK versions

**Database errors:**
- Clear app data and reinstall
- Verify database schema in database_service.dart

**Export issues:**
- Check file permissions
- Ensure storage space available

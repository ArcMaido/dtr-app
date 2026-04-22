# DTR App - Daily Time Record

A Flutter mobile application for tracking daily work hours and managing time records on Android and iOS platforms.

## Features

- **Time Tracking**: Record time in and time out for each workday
- **Daily Records**: Add notes and track daily activities
- **Calendar View**: Visualize your work schedule and hours worked per day
- **Data Export**: Export time records to CSV or JSON formats
- **Local Storage**: All data is stored locally on your device
- **Monthly Summary**: View total hours worked per month

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── home_screen.dart      # Main daily tracking screen
│   ├── calendar_screen.dart  # Calendar view with monthly overview
│   └── export_screen.dart    # Export and reporting screen
├── models/
│   └── time_record.dart      # TimeRecord data model
├── services/
│   ├── database_service.dart # SQLite database management
│   └── export_service.dart   # Data export functionality
├── widgets/
│   └── (custom widgets here)
└── utils/
    └── (utility functions here)
```

## Dependencies

- **intl**: Date and time formatting
- **path_provider**: Access to app directories
- **sqflite**: SQLite database for Flutter
- **shared_preferences**: Simple key-value storage
- **csv**: CSV data handling
- **permission_handler**: Handle app permissions

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android SDK and/or Xcode for iOS development

### Installation

1. Clone or navigate to the project directory:
```bash
cd DTR-APP
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Running on Specific Platforms

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

## Usage

### Daily Time Tracking

1. Open the app to the Home screen
2. Click "Time In" to record when you started work
3. Click "Time Out" to record when you finished
4. Add notes for the day (optional)
5. View your total hours worked

### Calendar View

1. Tap the "Calendar" tab in the bottom navigation
2. Navigate between months using the arrow buttons
3. View hours worked per day (color-coded: green for completed, orange for in-progress)
4. Click any day to see detailed information
5. View total monthly hours at the bottom

### Export Records

1. Tap the "Export" tab in the bottom navigation
2. Select start and end dates for the export range
3. Preview the records to be exported
4. Choose export format:
   - **CSV**: Spreadsheet-compatible format
   - **JSON**: Structured data format
5. Files are saved to your device's documents folder

## File Descriptions

### Models

**time_record.dart**
- `TimeRecord`: Main data model for daily time records
- Methods for time calculation, formatting, and database conversion

### Services

**database_service.dart**
- SQLite database initialization and management
- CRUD operations for time records
- Query methods for date ranges and summaries

**export_service.dart**
- Convert records to CSV and JSON formats
- File management for exports
- Timestamp generation for file naming

### Screens

**home_screen.dart**
- Main daily tracking interface
- Time In/Out recording buttons
- Notes editing
- Quick summary card

**calendar_screen.dart**
- Monthly calendar grid view
- Color-coded day cells
- Day details popup
- Monthly hours summary

**export_screen.dart**
- Date range selection
- Record preview and filtering
- Export format options
- Summary statistics

## Data Storage

All time records are stored in a local SQLite database (`dtr_app.db`) located in the app's documents directory.

## Troubleshooting

### Database Issues
- Delete and reinstall the app to reset the database
- Check app permissions for file access

### Export Issues
- Ensure app has permission to write files
- Check available storage space
- Verify date range selection

## Future Enhancements

- Cloud sync with Firebase
- Biometric authentication
- Multiple user support
- Offline sync when connectivity returns
- Customizable work hour templates
- Attendance reports and analytics

## License

This project is provided as-is for personal or commercial use.

## Support

For issues or feature requests, please refer to the project documentation or contact the development team.

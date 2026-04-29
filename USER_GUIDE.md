# DTR App User Guide

This guide explains what to install, what to do, and which commands to run so you can set up and run the DTR App.

## What to Download

Install the required tools from the official sources below:

- Flutter SDK: https://docs.flutter.dev/get-started/install
- Dart SDK: https://dart.dev/get-dart
- Android Studio: https://developer.android.com/studio
- Xcode for macOS and iOS builds: https://developer.apple.com/xcode/
- Git: https://git-scm.com/downloads

## What to Install First

1. Install Flutter SDK.
2. Install Android Studio for Android development.
3. Install Git if you do not already have it.
4. If you are building for iPhone or iPad, install Xcode on a Mac.

## What to Do After Downloading

1. Open the project folder in your editor.
2. Open a terminal in the project root.
3. Fetch the packages used by the app.
4. Run the app on a connected device or emulator.

## Commands to Use

From the project root, run these commands:

- flutter pub get
- flutter run
- flutter run -d android
- flutter run -d ios
- flutter build apk --release
- flutter build appbundle --release

## Where the App Files Come From

The app stores data locally on the device, so no extra server setup is needed. The export feature saves files to the device storage folders that the app can access.

## What the Export Screen Does

- Lets you choose a date range for records.
- Shows a preview of the records and rendered hours.
- Exports CSV, styled Excel, or PDF files.
- CSV is best for raw data.
- Excel gives you the designed report layout.
- Saves the exported file to the device storage location allowed by the platform.

## Notes Feature

- Use the Notes shortcut on the Home page to add a reason, reminder, or summary for today.
- Open a day in Calendar to edit notes for that specific date.
- A note icon appears on days that already have notes saved.

## Troubleshooting

- If Flutter is not recognized, restart your terminal after installing Flutter and make sure Flutter is added to your PATH.
- If Android builds fail, open Android Studio once so it can finish installing its components.
- If export fails, check file permissions and available storage space on the device.

## Quick Start Summary

1. Download Flutter from https://docs.flutter.dev/get-started/install.
2. Download Android Studio from https://developer.android.com/studio.
3. Run flutter pub get.
4. Run flutter run.

# Branding Assets

Place the app logo files in this folder:

- app_logo.png
  - Main square logo image (recommended 1024x1024 PNG)
  - This is used as the app icon source.

- app_logo_transparent.png
  - Transparent foreground-only version of the logo
  - Used for Android adaptive icon foreground.

After placing both files, run:

flutter pub get
flutter pub run flutter_launcher_icons

This will generate launcher icons for Android and iOS from these assets.

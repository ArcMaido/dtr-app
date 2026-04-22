#!/bin/bash
# This script helps set up the Flutter DTR App for development

echo "DTR App - Setup Script"
echo "====================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Get dependencies
echo "Installing dependencies..."
flutter pub get

# Generate any required code (if using build_runner in future)
# flutter pub run build_runner build

echo "Setup complete!"
echo ""
echo "To run the app:"
echo "  flutter run"
echo ""
echo "To build for Android:"
echo "  flutter build apk --release"
echo ""
echo "To build for iOS:"
echo "  flutter build ios --release"

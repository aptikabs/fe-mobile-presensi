#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

ENV_TARGET="${1:-prod}" # Default to 'prod' if not specified

echo "=========================================================="
echo "   FLUTTER RELEASE SECURITY BUILD AUTOMATION ($ENV_TARGET) "
echo "=========================================================="

SYMBOL_DIR="build/app/outputs/symbols"

echo "1. Cleaning build directory..."
flutter clean
flutter pub get

echo ""
echo "2. Creating symbols directory at: ${SYMBOL_DIR}..."
mkdir -p "${SYMBOL_DIR}"

echo ""
echo "3. Building obfuscated Android APK ($ENV_TARGET)..."
flutter build apk --dart-define=ENV="${ENV_TARGET}" --obfuscate --split-debug-info="${SYMBOL_DIR}" --release

if [ "$ENV_TARGET" = "prod" ]; then
  echo ""
  echo "4. Building obfuscated Android App Bundle (AAB) ($ENV_TARGET)..."
  flutter build appbundle --dart-define=ENV="${ENV_TARGET}" --obfuscate --split-debug-info="${SYMBOL_DIR}" --release
fi

echo ""
echo "=========================================================="
echo " SUCCESS: Build Release Obfuscated ($ENV_TARGET) Complete!"
echo " Debug Symbols Saved to: ${SYMBOL_DIR}"
echo "=========================================================="

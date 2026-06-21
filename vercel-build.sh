#!/bin/bash
set -e

echo "==> Cloning Flutter SDK (stable channel)..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "==> Adding Flutter to PATH..."
export PATH="$PATH:$(pwd)/flutter/bin"

echo "==> Running flutter doctor..."
flutter doctor

echo "==> Fetching dependencies..."
flutter pub get

echo "==> Building Flutter Web (release)..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "==> Build complete. Output in build/web"
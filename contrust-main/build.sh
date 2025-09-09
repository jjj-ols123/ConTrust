#!/bin/bash
set -e

# Download and setup Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$PWD/flutter/bin"

# Navigate to Flutter project and build
cd Back-End
flutter doctor --android-licenses || true
flutter config --enable-web
flutter pub get
flutter build web --base-href "/"

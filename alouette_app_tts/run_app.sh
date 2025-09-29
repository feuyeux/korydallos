#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add Homebrew to PATH on macOS
if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

cd "$SCRIPT_DIR"

# Check for pubspec.yaml
if [[ ! -f "pubspec.yaml" ]]; then
    echo "Error: pubspec.yaml not found"
    exit 1
fi

PLATFORM=${1:-macos}

echo "Starting Alouette TTS on $PLATFORM"
flutter pub outdated
flutter run -d "$PLATFORM" --debug
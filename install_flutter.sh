#!/bin/zsh
set -e

echo "==> Creating development directory..."
mkdir -p ~/development

echo "==> Downloading Flutter SDK v3.44.2 (macOS ARM64)..."
curl -L -# -o ~/development/flutter_sdk.zip https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.44.2-stable.zip

echo "==> Extracting Flutter SDK..."
unzip -q ~/development/flutter_sdk.zip -d ~/development

echo "==> Cleaning up zip archive..."
rm ~/development/flutter_sdk.zip

echo "==> Verifying Flutter SDK installation..."
~/development/flutter/bin/flutter --version

echo "==> Flutter installation complete!"

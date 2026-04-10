#!/usr/bin/env bash
# Publish alice_manager lên https://pub.dev
# Yêu cầu: đã đăng nhập `dart pub login` (hoặc có token PUB_CREDENTIALS).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if command -v fvm >/dev/null 2>&1; then
  DART="fvm dart"
  FLUTTER="fvm flutter"
  echo "Using FVM (see .fvmrc)"
else
  DART="dart"
  FLUTTER="flutter"
fi

echo "==> pub get"
$FLUTTER pub get

echo "==> analyze"
$DART analyze

echo "==> publish --dry-run (kiểm tra trước khi đẩy lên pub.dev)"
$DART pub publish --dry-run

echo ""
read -r -p "Chạy dart pub publish (không dry-run)? [y/N] " reply
if [[ "${reply:-}" =~ ^[Yy]$ ]]; then
  $DART pub publish
  echo "Xong."
else
  echo "Đã hủy. Khi sẵn sàng: $DART pub publish"
fi

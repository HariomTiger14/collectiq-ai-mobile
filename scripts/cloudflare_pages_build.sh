#!/usr/bin/env bash
set -euo pipefail

echo "CollectIQ AI Cloudflare Pages build"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required to install Flutter." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
  echo "Flutter not found on PATH. Installing stable Flutter to ${FLUTTER_HOME}..."

  if [ ! -d "${FLUTTER_HOME}/.git" ]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}"
  else
    git -C "${FLUTTER_HOME}" fetch origin stable --depth 1
    git -C "${FLUTTER_HOME}" checkout stable
    git -C "${FLUTTER_HOME}" pull --ff-only origin stable
  fi

  export PATH="${FLUTTER_HOME}/bin:${PATH}"
fi

flutter --version
flutter channel stable
flutter config --enable-web
flutter pub get
flutter build web --release

if [ ! -f "build/web/index.html" ]; then
  echo 'Error: expected build output "build/web/index.html" was not created.' >&2
  exit 1
fi

echo 'Cloudflare Pages build completed. Output directory: build/web'

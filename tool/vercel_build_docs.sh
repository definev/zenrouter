#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_version="${FLUTTER_VERSION:-3.47.0}"

if [[ -n "${FLUTTER_BIN:-}" ]]; then
  flutter_bin="${FLUTTER_BIN}"
elif command -v flutter >/dev/null 2>&1; then
  flutter_bin="$(command -v flutter)"
else
  flutter_sdk_dir="${repo_root}/.flutter-sdk/${flutter_version}"
  flutter_bin="${flutter_sdk_dir}/bin/flutter"

  if [[ ! -x "${flutter_bin}" ]]; then
    mkdir -p "$(dirname "${flutter_sdk_dir}")"
    git clone \
      --branch "${flutter_version}" \
      --depth 1 \
      https://github.com/flutter/flutter.git \
      "${flutter_sdk_dir}"
  fi
fi

"${flutter_bin}" config --no-analytics

cd "${repo_root}"
"${flutter_bin}" pub get

cd "${repo_root}/packages/zenrouter_docs"
"${flutter_bin}" build web --release

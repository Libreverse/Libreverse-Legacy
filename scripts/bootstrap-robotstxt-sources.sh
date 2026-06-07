#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
BASE="$ROOT/vendor/gems/google_robotstxt_parser/ext/robotstxt"

if [ ! -f "$BASE/robotstxt/robots.cc" ]; then
  rm -rf "$BASE/robotstxt"
  git clone https://github.com/google/robotstxt "$BASE/robotstxt"
  git -C "$BASE/robotstxt" checkout 86d5836ba2d5a0b6b938ab49501be0e09d9c276c
fi

if [ ! -f "$BASE/abseil-cpp/CMakeLists.txt" ]; then
  rm -rf "$BASE/abseil-cpp"
  git clone --branch 20250127.1 --depth 1 https://github.com/abseil/abseil-cpp "$BASE/abseil-cpp"
fi

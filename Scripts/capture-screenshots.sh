#!/bin/bash
# Runs the screenshot UITest; output goes to tmp/screenshots/ (gitignored)
# Usage: ./Scripts/capture-screenshots.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/tmp/screenshots"
mkdir -p "$OUTPUT_DIR"

SCREENSHOT_OUTPUT_DIR="$OUTPUT_DIR" xcodebuild \
  -scheme Geko \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test \
  -only-testing:GekoUITests/ScreenshotTests/testCaptureScreenshots

echo "Screenshots saved to $OUTPUT_DIR"

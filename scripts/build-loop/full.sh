#!/bin/zsh
# Full unit suite: full.sh <label> [YES|NO coverage]
set -u
SP=${SP:-/tmp/lifeos-build}; mkdir -p "$SP"
cd "/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS"
label=$1; cov=${2:-NO}
rm -rf "$SP/$label.xcresult"
xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -skip-testing:"ADHD LifeOSUITests" \
  -enableCodeCoverage "$cov" -resultBundlePath "$SP/$label.xcresult" > "$SP/$label.log" 2>&1
echo "XCODEBUILD_EXIT=$?" >> "$SP/$label.log"

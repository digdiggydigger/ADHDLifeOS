#!/bin/zsh
# Targeted unit run: t.sh <label> <TestClass> [<TestClass> ...]
# Builds and tests ONLY the named classes, coverage off (build-loop economy 1).
set -u
SP=${SP:-/tmp/lifeos-build}; mkdir -p "$SP"
cd "/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS"
label=$1; shift
only=()
for c in "$@"; do only+=("-only-testing:ADHD LifeOSTests/$c"); done
rm -rf "$SP/$label.xcresult"
xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -skip-testing:"ADHD LifeOSUITests" "${only[@]}" \
  -enableCodeCoverage NO -resultBundlePath "$SP/$label.xcresult" > "$SP/$label.log" 2>&1
echo "XCODEBUILD_EXIT=$?" >> "$SP/$label.log"
grep -E "error:|Executed|TEST (SUCCEEDED|FAILED)|XCODEBUILD_EXIT" "$SP/$label.log" | grep -v "^\s*$" | sort -u | head -60

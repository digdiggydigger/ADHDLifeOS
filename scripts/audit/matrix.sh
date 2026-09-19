#!/bin/zsh
# matrix.sh MODE  — MODE in L (light, large), D (dark, large), A (light, AX3)
SP="${AUDIT_SCRATCH:-/tmp/adhd-audit}"; D="$(cd "$(dirname "$0")" && pwd)"; mkdir -p "$SP/frames"
U=02AE86FA-CE2F-4468-90D6-2B8708910993; M=$1
case $M in L) xcrun simctl ui $U appearance light; xcrun simctl ui $U content_size large;;
           D) xcrun simctl ui $U appearance dark;  xcrun simctl ui $U content_size large;;
           A) xcrun simctl ui $U appearance light; xcrun simctl ui $U content_size accessibility-extra-large;; esac
sleep 2
for pair in "tabBar.Today:home:4" "tabBar.Tasks:tasks:3" "tabBar.Areas:areas:2" "tabBar.Journal:journal:2" "tabBar.Captures:captures:2" "tabBar.Tools:tools:2"; do
  id=${pair%%:*}; rest=${pair#*:}; name=${rest%%:*}; pages=${rest#*:}
  [ $M = A ] && pages=$((pages+2))
  python3 "$D/tapid.py" $id >/dev/null; sleep 3.5
  "$D/cap.sh" "s-$name-$M" $pages
done
python3 "$D/tapid.py" tabBar.Today >/dev/null

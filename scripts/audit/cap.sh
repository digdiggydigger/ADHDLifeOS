#!/bin/zsh
# usage: cap.sh NAME PAGES  — scroll to top, then shoot PAGES frames scrolling ~420pt each
U=02AE86FA-CE2F-4468-90D6-2B8708910993
F="${AUDIT_SCRATCH:-/tmp/adhd-audit}/frames"
N=$1; P=${2:-3}
[ "$3" = "sheet" ] || for i in 1 2 3 4; do idb ui swipe --udid $U --duration 0.15 200 250 200 750 >/dev/null 2>&1; done
sleep 1.2
for p in $(seq 1 $P); do
  xcrun simctl io $U screenshot --type=jpeg "$F/$N-p$p.jpg" >/dev/null 2>&1
  [ $p -lt $P ] && { idb ui swipe --udid $U --duration 0.5 200 600 200 190 >/dev/null 2>&1; sleep 1.3; }
done
echo "$N: $P pages"

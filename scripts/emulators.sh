#!/usr/bin/env bash
#
# Starts the Firebase Emulator Suite for the `FirebaseManager*Tests` integration tests
# (+Seed, +Tags, +AccountDeletion, +Storage). Without it running those tests SKIP — they never
# fail the suite, and they never fall through to the live project.
#
# Two things this script exists to encode, both of which cost a session to rediscover:
#
#  1. firebase-tools 15.x requires **Java 21+** (not the 11+ older notes claim, and not the 17
#     that happens to be installed here). It exits with "no longer supports Java version before
#     21" otherwise.
#  2. Homebrew keeps multiple JDKs **keg-only**, so `java -version` reports whatever was linked
#     first — 1.8 on this machine — regardless of what is installed. `brew link openjdk@21`
#     would fix that globally but changes the system default Java for everything else, so this
#     script points JAVA_HOME at the keg for its own process instead.
#
set -euo pipefail

JDK="${LIFEOS_JDK_HOME:-/opt/homebrew/opt/openjdk@21}"

if [[ ! -x "$JDK/bin/java" ]]; then
  echo "error: no JDK 21 at $JDK" >&2
  echo "  install it with:  brew install openjdk@21" >&2
  echo "  (leave it keg-only — do NOT 'brew link' it; this script uses it directly)" >&2
  echo "  or point LIFEOS_JDK_HOME at another JDK 21+." >&2
  exit 1
fi

export JAVA_HOME="$JDK"
export PATH="$JAVA_HOME/bin:$PATH"

cd "$(dirname "$0")/.."

# The project id must match GoogleService-Info.plist's, or the app's requests address a
# different (empty) project inside the emulator and every read comes back empty.
exec firebase emulators:start \
  --only auth,firestore,storage \
  --project adhdlifeos-acb49 \
  "$@"

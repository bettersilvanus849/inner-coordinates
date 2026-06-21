#!/usr/bin/env bash
# pay-keypad.sh — type a 6-digit pay password on the iPhone-Mirroring keypad,
# reading the password from the macOS Keychain. The password is NEVER in this
# file or the repo — only in your local, encrypted Keychain.
#
# ARM IT FIRST (one time, by the user — opt-in):
#   security add-generic-password -a meituan -s ic-alipay-pay -w
#   (prompts for the password; nothing secret is passed on the command line.)
#
# SAFETY: entering 6 digits AUTO-SUBMITS the payment. Run ONLY when the 6-digit
# keypad is actually on screen AND the order/amount has been verified. The agent
# should ASK before invoking this (opt-in per use) — never pay silently/by default.
#
#   lib/pay-keypad.sh            # types the armed password; or prints how to arm
set -uo pipefail
PROC="iPhone Mirroring"
ACCOUNT="${IC_PAY_ACCOUNT:-meituan}"
SERVICE="${IC_PAY_SERVICE:-ic-alipay-pay}"

PW="$(security find-generic-password -a "$ACCOUNT" -s "$SERVICE" -w 2>/dev/null || true)"
if [ -z "$PW" ]; then
  echo "no password armed for $ACCOUNT/$SERVICE." >&2
  echo "arm it once:  security add-generic-password -a $ACCOUNT -s $SERVICE -w" >&2
  exit 1
fi

# digit -> keypad coordinate (iPhone Mirroring normalized window 0,30 / 346x760)
coord(){ case "$1" in
  1) echo 63,600;;  2) echo 172,600;; 3) echo 282,600;;
  4) echo 63,645;;  5) echo 172,645;; 6) echo 282,645;;
  7) echo 63,690;;  8) echo 172,690;; 9) echo 282,690;;
  0) echo 172,735;; *) echo "";; esac; }

osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set frontmost to true" >/dev/null 2>&1
sleep 0.3
n=0
for ((i=0; i<${#PW}; i++)); do
  c="$(coord "${PW:$i:1}")"; [ -z "$c" ] && continue
  peekaboo click --coords "$c" >/dev/null 2>&1
  sleep 0.35; n=$((n+1))
done
echo "entered $n digits on the keypad"

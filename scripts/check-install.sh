#!/usr/bin/env bash
# Checks the published repository the way a new user meets it: on a clean
# system (run as root in a fresh ubuntu:24.04 or debian:trixie container),
# follow the README's steps word for word, install all three apps, check
# every program finds its libraries, then check an older version upgrades.
#   scripts/check-install.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
APPS=(theatre tvcast bittrader)

# A desktop already has these; a bare container doesn't.
apt-get update -qq
apt-get install -y -qq wget ca-certificates >/dev/null
sudo() { "$@"; }   # containers run as root and have no sudo

echo "== The README's steps"
sudo install -d -m 0755 /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/volpesmedia.gpg https://volpesmedia.github.io/apt/volpesmedia.gpg
sudo wget -qO /etc/apt/sources.list.d/volpesmedia.sources https://volpesmedia.github.io/apt/volpesmedia.sources
sudo apt update
sudo apt install -y "${APPS[@]}"

echo "== Every program finds its libraries"
status=0
for app in "${APPS[@]}"; do
  echo "$app $(dpkg-query -W -f='${Version}' "$app")"
  for bin in $(dpkg -L "$app" | grep '^/usr/bin/'); do
    if ldd "$bin" | grep 'not found'; then
      echo "::error::$bin is missing libraries"; status=1
    fi
  done
done

echo "== An older version upgrades with apt upgrade"
old="$(apt-cache madison theatre | awk '{print $3}' | sort -V | head -1)"
new="$(apt-cache madison theatre | awk '{print $3}' | sort -V | tail -1)"
if [ "$old" != "$new" ]; then
  apt-get install -y -qq --allow-downgrades "theatre=$old" >/dev/null
  sudo apt upgrade -y
  got="$(dpkg-query -W -f='${Version}' theatre)"
  [ "$got" = "$new" ] || { echo "::error::theatre stayed at $got, expected $new"; status=1; }
  echo "theatre $old -> $got"
fi
exit $status

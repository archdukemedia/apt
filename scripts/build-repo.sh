#!/usr/bin/env bash
# Builds the apt repository from a folder of .deb files.
#   scripts/build-repo.sh <debs-dir> <out-dir>
# Signs it with the key in $GNUPGHOME whose fingerprint matches
# site/volpesmedia.gpg; with UNSIGNED=1 it skips signing (local tries only).
#
# Layout (one suite for every supported system, see README.md):
#   <out>/pool/main/<letter>/<package>/<package>_<version>_amd64.deb
#   <out>/dists/stable/{Release,InRelease,Release.gpg}
#   <out>/dists/stable/main/binary-amd64/Packages{,.gz,.xz}
#   <out>/volpesmedia.gpg, volpesmedia.asc, volpesmedia.sources, index.html
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEBS="${1:?usage: build-repo.sh <debs-dir> <out-dir>}"
OUT="${2:?usage: build-repo.sh <debs-dir> <out-dir>}"
# Only these packages belong here. Older releases of Trader were called
# "trader" (a name Ubuntu already uses), so they are left out on purpose.
PACKAGES=" theatre tvcast bittrader "

rm -rf "$OUT"
mkdir -p "$OUT/pool/main" "$OUT/dists/stable/main/binary-amd64"
cp "$ROOT"/site/* "$OUT/"

count=0
for deb in "$DEBS"/*.deb; do
  [ -e "$deb" ] || continue
  pkg="$(dpkg-deb --field "$deb" Package)"
  arch="$(dpkg-deb --field "$deb" Architecture)"
  ver="$(dpkg-deb --field "$deb" Version)"
  if [[ "$PACKAGES" != *" $pkg "* || "$arch" != amd64 ]]; then
    echo "Skipping $(basename "$deb") ($pkg, $arch)"
    continue
  fi
  dir="$OUT/pool/main/${pkg:0:1}/$pkg"
  mkdir -p "$dir"
  cp "$deb" "$dir/${pkg}_${ver}_${arch}.deb"
  count=$((count + 1))
done
[ "$count" -gt 0 ] || { echo "No packages found in $DEBS" >&2; exit 1; }

TMP_RELEASE="$(mktemp)"
trap 'rm -f "$TMP_RELEASE"' EXIT
cd "$OUT"
BIN=dists/stable/main/binary-amd64
apt-ftparchive packages pool/main > "$BIN/Packages"
gzip -9nk "$BIN/Packages"
xz -9k "$BIN/Packages"

apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="Volpes-Media" \
  -o APT::FTPArchive::Release::Label="Volpes-Media" \
  -o APT::FTPArchive::Release::Suite="stable" \
  -o APT::FTPArchive::Release::Codename="stable" \
  -o APT::FTPArchive::Release::Architectures="amd64" \
  -o APT::FTPArchive::Release::Components="main" \
  -o APT::FTPArchive::Release::Description="Theatre, TvCast and BitTrader from Volpes-Media" \
  release dists/stable > "$TMP_RELEASE"
mv "$TMP_RELEASE" dists/stable/Release
chmod 644 dists/stable/Release

if [ "${UNSIGNED:-0}" != 1 ]; then
  # Sign with the key whose public half is published, never another one.
  fpr="$(gpg --show-keys --with-colons "$ROOT/site/volpesmedia.gpg" | awk -F: '/^fpr/{print $10; exit}')"
  gpg --batch --yes --digest-algo SHA512 --local-user "$fpr" --clearsign \
      --output dists/stable/InRelease dists/stable/Release
  gpg --batch --yes --digest-algo SHA512 --local-user "$fpr" --armor --detach-sign \
      --output dists/stable/Release.gpg dists/stable/Release
  gpgv --keyring "$ROOT/site/volpesmedia.gpg" dists/stable/InRelease
fi

echo "Built $OUT with $count packages:"
grep -E '^(Package|Version):' "$BIN/Packages" | paste - - | sed 's/^/  /'

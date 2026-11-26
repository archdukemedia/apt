#!/usr/bin/env bash
# Downloads the .deb files of the newest releases of each Arch-Duke Media app.
#   scripts/fetch-debs.sh <out-dir>
# GitHub Releases are the source of truth: nothing is kept between runs, the
# whole repository is rebuilt from them each time. Needs GH_TOKEN with read
# access to the app repositories (they are private).
set -euo pipefail
OUT="${1:?usage: fetch-debs.sh <out-dir>}"
KEEP="${KEEP:-3}"   # releases kept per app, so people can go back a version
APPS=(archdukemedia/theatre archdukemedia/herald archdukemedia/merchant)

mkdir -p "$OUT"
for repo in "${APPS[@]}"; do
  tags="$(gh release list -R "$repo" --limit "$KEEP" --exclude-drafts --exclude-pre-releases \
            --json tagName --jq '.[].tagName')"
  if [ -z "$tags" ]; then
    echo "::warning::$repo has no releases" >&2
    continue
  fi
  for tag in $tags; do
    gh release download "$tag" -R "$repo" --pattern '*_amd64.deb' --dir "$OUT" --skip-existing
    echo "$repo $tag"
  done
done

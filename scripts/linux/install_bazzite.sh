#!/usr/bin/env bash
set -euo pipefail

REPO="SteamClientHomebrew/Millennium"
DEST="/var/lib/millennium"
STEAM="${STEAM_PATH:-$HOME/.steam/steam}"

for cmd in curl tar jq perl sudo strings grep sha256sum cp chmod mv mktemp rm sed ln mkdir; do
  command -v "$cmd" >/dev/null || { echo "error: $cmd not installed" >&2; exit 1; }
done

WORK="$(mktemp -d "${TMPDIR:-/tmp}/millennium-bazzite.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "fetching latest Millennium release"
TAG=$(curl -fsSL -H 'Accept: application/vnd.github.v3+json' \
  "https://api.github.com/repos/${REPO}/releases" \
  | jq -r '[.[] | select(.prerelease == false)] | first | .tag_name')
[ -n "$TAG" ] && [ "$TAG" != "null" ] || { echo "error: could not determine latest release" >&2; exit 1; }

VERSION="${TAG#v}"
ARCHIVE="millennium-v${VERSION}-linux-x86_64.tar.gz"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}"
echo "downloading Millennium ${VERSION}"
curl -fL --progress-bar -o "$WORK/millennium.tar.gz" "$URL"

SHA=$(curl -fsSL \
  "https://github.com/${REPO}/releases/download/${TAG}/millennium-v${VERSION}-linux-x86_64.sha256" \
  2>/dev/null || true)
if [ -n "$SHA" ]; then
  (cd "$WORK" && printf '%s\n' "$SHA" | sed "s|${ARCHIVE}|millennium.tar.gz|" | sha256sum -c --status) \
    || { echo "error: checksum mismatch" >&2; exit 1; }
  echo "checksum ok"
else
  echo "warning: release checksum unavailable; continuing without checksum verification" >&2
fi

tar -xzf "$WORK/millennium.tar.gz" -C "$WORK"
SRC="$WORK/usr/lib/millennium"
[ -d "$SRC" ] || { echo "error: unexpected tarball layout" >&2; exit 1; }

echo "patching installation paths"
perl -pi -e 's|/usr/lib/millennium|/var/lib/millennium|g' "$SRC"/*
if strings "$SRC"/* | grep -qF '/usr/lib/millennium'; then
  echo "error: unpatched installation paths remain" >&2
  exit 1
fi

echo "installing Millennium to ${DEST}"
sudo mkdir -p "$DEST"
sudo cp -f "$SRC"/* "$DEST/"
sudo chmod +x "$DEST/libmillennium_pvs64" "$DEST/libmillennium_luavm_x86"

U32="$STEAM/ubuntu12_32"
U64="$STEAM/ubuntu12_64"
mkdir -p "$U32" "$U64"

echo "installing Millennium bootstrap libraries into Steam"
ln -sfn "$DEST/libmillennium_bootstrap_x86.so" "$U32/libXtst.so.6"

# Bazzite's Steam webhelper needs real files here rather than links into /var/lib.
copy_into_steam() {
  local source="$1"
  local target="$2"
  local temporary="${target}.tmp.$$"

  cp "$source" "$temporary"
  chmod --reference="$source" "$temporary"
  mv -fT "$temporary" "$target"
}

copy_into_steam "$DEST/libmillennium_bootstrap_hhx64.so" "$U64/libXtst.so.6"
copy_into_steam "$DEST/libmillennium_hhx64.so" "$U64/libmillennium_hhx64.so"

echo "done; restart Steam"

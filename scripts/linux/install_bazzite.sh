#!/usr/bin/env bash
set -euo pipefail

REPO="SteamClientHomebrew/Millennium"
PATCH_REPO="JankyMouse/Millennium-Bazzite"
MILLENNIUM_TAG="v3.5.0"
PATCH_TAG="v3.5.0-bazzite.2"
DEST="/var/lib/millennium"
STEAM="${STEAM_PATH:-$HOME/.steam/steam}"

for cmd in curl tar perl sudo strings grep sha256sum cp chmod mv mktemp rm sed ln mkdir; do
  command -v "$cmd" >/dev/null || { echo "error: $cmd not installed" >&2; exit 1; }
done

WORK="$(mktemp -d "${TMPDIR:-/tmp}/millennium-bazzite.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

VERSION="${MILLENNIUM_TAG#v}"
ARCHIVE="millennium-v${VERSION}-linux-x86_64.tar.gz"
UPSTREAM_URL="https://github.com/${REPO}/releases/download/${MILLENNIUM_TAG}/${ARCHIVE}"
PATCH_URL="https://github.com/${PATCH_REPO}/releases/download/${PATCH_TAG}"
echo "downloading Millennium ${MILLENNIUM_TAG}"
curl -fL --progress-bar -o "$WORK/millennium.tar.gz" "$UPSTREAM_URL"

SHA=$(curl -fsSL \
  "https://github.com/${REPO}/releases/download/${MILLENNIUM_TAG}/millennium-v${VERSION}-linux-x86_64.sha256" \
  2>/dev/null || true)
if [ -n "$SHA" ]; then
  (cd "$WORK" && printf '%s\n' "$SHA" | sed "s|${ARCHIVE}|millennium.tar.gz|" | sha256sum -c --status) \
    || { echo "error: checksum mismatch" >&2; exit 1; }
  echo "checksum ok"
else
  echo "warning: release checksum unavailable; continuing without checksum verification" >&2
fi

echo "downloading Bazzite-patched helper ${PATCH_TAG}"
curl -fL --progress-bar -o "$WORK/libmillennium_hhx64.so" \
  "${PATCH_URL}/libmillennium_hhx64.so"
curl -fsSL -o "$WORK/libmillennium_hhx64.so.sha256" \
  "${PATCH_URL}/libmillennium_hhx64.so.sha256"
read -r PATCH_SHA _ < "$WORK/libmillennium_hhx64.so.sha256"
if [[ ! "$PATCH_SHA" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "error: invalid patched-helper checksum file" >&2
  exit 1
fi
printf '%s  %s\n' "$PATCH_SHA" "$WORK/libmillennium_hhx64.so" | sha256sum -c --status \
  || { echo "error: patched-helper checksum mismatch" >&2; exit 1; }

tar -xzf "$WORK/millennium.tar.gz" -C "$WORK"
SRC="$WORK/usr/lib/millennium"
[ -d "$SRC" ] || { echo "error: unexpected tarball layout" >&2; exit 1; }

echo "patching installation paths"
perl -pi -e 's|/usr/lib/millennium|/var/lib/millennium|g' "$SRC"/*
if strings "$SRC"/* | grep -qF '/usr/lib/millennium'; then
  echo "error: unpatched installation paths remain" >&2
  exit 1
fi

cp "$WORK/libmillennium_hhx64.so" "$SRC/libmillennium_hhx64.so"

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

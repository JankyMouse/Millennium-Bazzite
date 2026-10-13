# Bazzite installation draft

This is a community-maintained Bazzite installation draft, not an official Millennium release or package.

Run `scripts/linux/install_bazzite.sh` to install the latest official Linux x86_64 Millennium release. It keeps Millennium's libraries in `/var/lib/millennium`, links the 32-bit bootstrap as usual, and copies the two 64-bit webhelper libraries into Steam's `ubuntu12_64` directory. Copying avoids the webhelper access issue seen with links into `/var/lib`.

The route MIME fix is a separate source change in `src/instrumentation/loopback/src/url.rs`. The installer downloads prebuilt upstream releases; it will include that fix only after a release containing the change is published. Until then, the helper must be built from the patched source and installed separately.

Set `STEAM_PATH` if Steam is installed somewhere other than `~/.steam/steam`.

## Proposed changes

- Return `text/html` for extensionless Steam UI routes under `/routes/`, preventing Chromium from treating `/routes/library/home` as a file download.
- Install real 64-bit Millennium helper files in Steam's webhelper directory on Bazzite instead of symlinking those files into `/var/lib`.

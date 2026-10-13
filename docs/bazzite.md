# Bazzite installation preview

This is a community-maintained Bazzite preview, not an official Millennium release or package.

Run `scripts/linux/install_bazzite.sh` to install the Millennium v3.5.0 Linux x86_64 release with this repository's patched 64-bit helper. It keeps Millennium's libraries in `/var/lib/millennium`, links the 32-bit bootstrap as usual, and copies the patched bootstrap and helper into Steam's `ubuntu12_64` directory. The copies avoid the Bazzite webhelper access issue seen with links into `/var/lib`.

The helper corrects the MIME type for extensionless Steam UI routes under `/routes/`; without that, `/routes/library/home` can be treated as a file download. The installer pins Millennium v3.5.0 because the patched helper was built from that source version. Keep the upstream source version and patched-helper release paired.

Set `STEAM_PATH` if Steam is installed somewhere other than `~/.steam/steam`.

## Changes in this preview

- Return `text/html` for extensionless Steam UI routes under `/routes/`.
- Install real 64-bit Millennium helper files in Steam's webhelper directory on Bazzite.

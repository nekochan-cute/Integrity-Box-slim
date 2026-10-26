# Integrity Box Slim

A stripped-down [Integrity Box](https://github.com/MeowDump/Integrity-Box).

It is the unmodified upstream [PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) by osm0sis (included as a submodule) plus a few small scripts that set up the Tricky Store keybox and target list. The module ID is still `playintegrityfix`, so it installs over Integrity Box or PIF.

## Requirements

- Magisk, KernelSU or APatch
- Zygisk (built into Magisk, or Zygisk Next etc.)
- [Tricky Store OSS](https://github.com/beakthoven/TrickyStoreOSS) or a compatible module

## Usage

Flash the zip, reboot, then press the module's Action button. The action:

1. downloads the Integrity Box keybox to `/data/adb/tricky_store/keybox.xml`
2. writes `/data/adb/tricky_store/target.txt` (Google apps, key attestation apps and all user apps)
3. runs PIF's `autopif4.sh`, which fetches a Pixel Canary fingerprint, updates `security_patch.txt` and restarts Play Services and the Play Store

Nothing is downloaded during installation. No fingerprint is bundled, so spoofing starts after the first Action.

An existing `custom.pif.prop` from Integrity Box is kept; its `spoofPixel` and `spoofApps` entries are removed since upstream PIF does not use them.

## WebUI

KernelSU, APatch and MMRL open it from the module list. On Magisk use [KsuWebUI Standalone](https://github.com/5ec1cff/KsuWebUIStandalone) or MMRL.

It shows the module, fingerprint and keybox state, runs the Action, checks the keybox against Google's revocation list, loads a keybox file from `/sdcard` (which turns on `keep-keybox`), and edits the options below, `target.txt` and PIF's Advanced Settings.

## Options

Files in `/data/adb/Box-Brain`:

- `keep-keybox`: do not download the keybox
- `blacklist.txt`: package names to leave out of `target.txt`, one per line
- `hash.txt`: VBMeta digest (SHA-256) to set as `ro.boot.vbmeta.digest` on boot
- `NoLineageProp`: delete properties with `lineage` in their name on boot
- `zygisk`: switch to PIF's scripts-only mode on the next install

If `/data/adb/tricky_store/tee_status` contains `teeBroken=true`, every `target.txt` entry gets a `!` suffix.

All PIF settings (`custom.pif.prop`, `skipmatchdevice`, `skipdelprop`, `skippersistprop`, ...) work as described in the [PlayIntegrityFork README](https://github.com/osm0sis/PlayIntegrityFork#readme).

The first `keybox.xml` and `target.txt` that get replaced are saved as `.bak` and restored on uninstall, together with removing `/data/adb/Box-Brain`.

## Differences from Integrity Box

- Upstream PlayIntegrityFork instead of the MeowDump fork, so no `spoofPixel`, per-app spoofing or pause switch
- A single-page WebUI instead of the 24-page one, no images, translations or install animation
- No Telegram link opened on install, no removal of other modules
- No DNS changes, direct IP downloads or `setenforce 0` while fetching the keybox
- No forced `system.prop`, root manager file mover, TWRP folder renamer or background daemon
- No `updateJson`, so root managers do not offer the full Integrity Box as an update

## Building

```sh
git submodule update --init --recursive
sh build.sh --gradle
```

Needs JDK 21 and the Android SDK. The zip is written to `out/`. GitHub Actions builds the same way.

## Credits

- [MeowDump](https://github.com/MeowDump) for Integrity Box
- [osm0sis](https://github.com/osm0sis) and chiteroman for PlayIntegrityFork

Licensed under GPL-3.0.

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
3. runs PIF's `autopif4.sh`, which fetches a Pixel Canary fingerprint
4. applies the integrity setup below and restarts Play Services and the Play Store

Nothing is downloaded during installation. No fingerprint is bundled, so spoofing starts after the first Action.

An existing `custom.pif.prop` from Integrity Box is kept; its `spoofPixel` and `spoofApps` entries are removed since upstream PIF does not use them. A legacy `custom.pif.json` is converted with upstream PIF's migration script when Tricky Store is active, with the original saved as `custom.pif.json.bak`.

## Integrity setup

Installation, Action and the post-boot service apply the same setup:

- Disable a conflicting ROM PIF profile stored in the owner user's `Settings.Secure.spoof_pif_config`. The original is saved in `/data/adb/Box-Brain/rom-pif-config`. `skippersistprop` opts out of this, and scripts-only mode leaves ROM spoofing alone.
- Set `spoofProvider=0` when Tricky Store is enabled and a keybox is present, so PIF does not replace the Keystore provider needed for hardware attestation. Other PIF options are preserved.
- Create a missing `security_patch.txt` using the fingerprint's patch date. Tricky Store OSS and compatible TEE simulators also get the upstream `[com.google.android.gms]` / `system=no` default.
- Keep global patch dates aligned after Action, even if data directories from a removed OMK or TEE-SIM installation remain. Existing `all=device_default` and per-package patch overrides are preserved.

The boot service restarts DroidGuard and the Play Store only if this setup changed a setting. It does not clear app data or download anything.

## WebUI

KernelSU, APatch and MMRL open it from the module list. On Magisk use [KsuWebUI Standalone](https://github.com/5ec1cff/KsuWebUIStandalone) or MMRL.

It shows the module, fingerprint and keybox state, runs the Action, checks the keybox against Google's revocation list, loads a keybox file from `/sdcard` (which turns on `keep-keybox`), applies the Hide My Applist config, and edits the options below, `target.txt` and PIF's Advanced Settings.

The Action, the revocation check and the HMA config run through the manager's `ksu.spawn`, so the page stays responsive and the Action log is shown while it runs. Other controls are disabled until the Action finishes. Managers without `ksu.spawn` fall back to `ksu.exec`, which blocks the page until the command ends.

## Hide My Applist

`hma-config.json` is Integrity Box's Hide My Applist config (Meow Blacklist / Whitelist templates). The WebUI's "Apply HMA config" runs `hma.sh`, which picks the first installed app of HMA-OSS (`org.frknkrc44.hma_oss`), `com.google.android.hmal` and Hide My Applist (`com.tsng.hidemyapplist`):

- Hide My Applist and `com.google.android.hmal` load `files/config.json` from their app data on launch and sync it to their service. The script writes the config there, launches the app and waits until the app has rewritten the file. If it does not, the previous config is restored.
- HMA-OSS keeps the config in its service directory `/data/misc/hide_my_applist_*`. The service reads it on boot, so the config applies after a reboot; long-pressing the status card in HMA-OSS reloads it right away.

The current config is first saved as `/data/adb/HMA/config_<date>.json`, which is kept on uninstall. The new config is written into the existing file so it keeps its owner and SELinux label. If no HMA app is installed, the HMA-OSS releases page is opened. HMA itself still has to be enabled in LSPosed.

## Options

Files in `/data/adb/Box-Brain`:

- `keep-keybox`: do not download the keybox
- `blacklist.txt`: package names to leave out of `target.txt`, one per line
- `hash.txt`: VBMeta digest (SHA-256) to set as `ro.boot.vbmeta.digest` on boot
- `NoLineageProp`: delete properties with `lineage` in their name on boot
- `zygisk`: switch to PIF's scripts-only mode on the next install

If `/data/adb/tricky_store/tee_status` contains `teeBroken=true`, every `target.txt` entry gets a `!` suffix.

PIF settings (`custom.pif.prop`, `skipmatchdevice`, `skipdelprop`, `skippersistprop`, ...) otherwise work as described in the [PlayIntegrityFork README](https://github.com/osm0sis/PlayIntegrityFork#readme). The integrity setup reapplies `spoofProvider=0` while Tricky Store and a keybox are active.

The first `keybox.xml` and `target.txt` that get replaced are saved as `.bak` and restored on uninstall, together with removing `/data/adb/Box-Brain`. A saved ROM PIF profile is restored only if the ROM setting is still empty; a newer user-selected profile is not overwritten.

## Differences from Integrity Box

- Upstream PlayIntegrityFork instead of the MeowDump fork, so no `spoofPixel`, per-app spoofing or pause switch
- A single-page WebUI instead of the 24-page one, no images, translations or install animation
- No Telegram link opened on install, no removal of other modules
- No DNS changes, direct IP downloads or `setenforce 0` while fetching the keybox or applying the HMA config
- No forced `system.prop`, root manager file mover, TWRP folder renamer or background daemon
- No `updateJson`, so root managers do not offer the full Integrity Box as an update

## Building

```sh
git submodule update --init --recursive
sh build.sh --gradle
```

Needs JDK 21 and the Android SDK. The zip is written to `out/`. GitHub Actions builds the same way.

## Changes

### v45-slim.1

- Fixed Keep keybox appearing enabled when all option flags are absent.
- Prevented ROM PIF profiles and Keystore provider replacement from interfering with Tricky Store.
- Restored missing attestation patch configuration and kept global dates updated despite leftover OMK/TEE-SIM directories.

## Credits

- [MeowDump](https://github.com/MeowDump) for Integrity Box
- [osm0sis](https://github.com/osm0sis) and chiteroman for PlayIntegrityFork

Licensed under GPL-3.0.

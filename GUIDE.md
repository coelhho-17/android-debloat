# Android Debloat — Reusable Guide (ADB, no root)

A guide to remove bloat from an Android phone (Samsung/One UI or another OEM) over USB (or wireless debugging) using ADB. Everything is reversible per-user and requires no root — which makes it inherently safer than Windows debloating. Written so either an AI agent or a human can follow it.

## How it works

Debloating runs through ADB (Android Debug Bridge), not root. The core commands:

```bash
adb shell pm uninstall --user 0 <package>     # removes the app for user 0 only; the system image keeps it
adb shell pm disable-user --user 0 <package>  # more conservative: disable without removing
adb shell pm install-existing <package>       # rollback (reinstall what was removed)
adb shell pm enable <package>                 # rollback (re-enable what was disabled)
```

## Prerequisites

PC (once):

- Install ADB: `winget install --id Google.PlatformTools --exact --accept-source-agreements --accept-package-agreements`.
- The current shell does NOT pick up the new PATH until restarted — locate the binary and export it instead:
  `export ADB=$(find "$LOCALAPPDATA/Microsoft/WinGet" -iname adb.exe | head -1)` (Windows / git-bash). On Linux/macOS, `adb` is usually on PATH after `sudo apt install adb` / `brew install android-platform-tools`.

Phone:

- Developer options: Settings → About phone → Software information → tap "Build number" 7 times.
- Settings → Developer options → enable "USB debugging".
- Plug in, unlock, and accept the "Allow USB debugging?" popup (tick "always allow from this computer").

## Wireless debugging (USB-driver fallback)

If `adb devices` stays empty even with USB debugging on and the popup accepted, the USB driver may be the problem — the ADB interface can be hijacked by inbox/generic WinUSB, and the current Samsung USB Driver drops older devices (e.g. the S22 Ultra's USB ID is absent). Don't fight the driver; go wireless (Android 11+):

1. Phone and PC on the same WiFi.
2. Settings → Developer options → Wireless debugging → ON.
3. On PC: `adb mdns services` → find `_adb-tls-connect` (IP:port) and `_adb-tls-pairing`.
4. `adb pair <ip>:<pair-port> <6-digit-code>` (code from the phone's "Pair device with pairing code" screen).
5. `adb connect <ip>:<connect-port>`.

Pairing persists across reboots: after a reboot, just re-run `adb mdns services` and `adb connect` (no re-pair; the IP/port may change).

## Golden rules (what to NEVER remove)

- Launcher and System UI (One UI Home, System UI, Settings) — removing them can soft-brick the screen.
- Knox and core Samsung framework services (`com.samsung.android.*` core) — many apps depend on them.
- Google Play Services (`com.google.android.gms`) and its dependencies (gsf, webview) — breaks Google login.
- The SMS app (may be Google Messages — the only SMS app on modern Samsung).
- Camera, dialer, the keyboard in use, Find My Mobile, system update (soagent + wssyncmldm).
- `com.samsung.android.kgclient` (Samsung Payment Services) — removing it can lock the device with a full-screen overlay.

## Procedure

1. Verify ADB sees the device: `adb devices -l` — expect `<serial> device`. `unauthorized` = accept the popup; empty = USB debugging is off.
2. Recon (read-only): `adb shell pm list packages --user 0` (all), `-d` (disabled), `-e` (enabled). Save to files. Get make/version: `adb shell getprop ro.product.manufacturer` and `ro.build.version.release`.
3. Classify against a curated UAD (Universal Android Debloater) list into REMOVE / DISABLE / KEEP — never guess from package names alone.
4. Present a plan report (REMOVE / DISABLE / KEEP, one-line justification each) and STOP for explicit approval before changing anything. Ask "Approve this plan?".
5. Execute one package per line, saving the removed list to a file.
6. Verify: re-list and confirm each target is gone (removed) or in the disabled list.
7. Generate a rollback script: one `pm install-existing` per removed package + one `pm enable` per disabled one, saved next to the package list.
8. Report before/after counts only from the captured lists — never hand-estimated totals.

## Curated lists (Samsung / One UI)

Safe to remove: Bixby (Voice/Vision/Routines), Game Launcher/Game Tools/GOS, AR Zone/AR Emoji, Samsung Pay/Pass/Wallet, SmartThings, Global Goals, Samsung Free, Galaxy Store (only if unused), Samsung Notes/Health/Members (if unused), preinstalled third-party (Facebook stubs, Microsoft, Netflix, Spotify, LinkedIn...), and Samsung telemetry/analytics.

Keep: One UI Home (launcher), System UI, `com.samsung.android.knox.*`, Samsung service framework (`com.samsung.android.service.*`), Google Play Services (gms) and dependencies, Device Care/battery, and any package required by hardware features the user relies on (camera, S Pen, Good Lock).

See `lists/remove.txt` and `lists/keep.txt` for the full per-package breakdown.

## Pitfalls

- "USB tethering" is NOT USB debugging — it shares the phone's internet with the PC. If the phone shows up only as a media device, check whether USB debugging (not tethering) is on.
- Empty `adb devices` while Windows sees the phone: run `Get-PnpDevice -PresentOnly`. A Class "WPD" (portable/media) device means cable/MTP are fine but the ADB interface is absent → USB debugging is OFF, not a driver problem.
- `adb shell` steals stdin inside a `while read` loop — without `< /dev/null`, the loop processes only 1 package and dies silently.
- CRLF in the package list breaks `pm uninstall`: a Windows `open(fn,'w')` writes CRLF, and `while IFS= read -r p` keeps a trailing `\r`, so every `pm uninstall` fails with `Failure [not installed for 0]`. Normalize first: `sed -i 's/\r$//' list.txt`.
- Protected Samsung packages return `Failure [DELETE_FAILED_OWNER_BLOCKED]` (spayfw) or `DELETE_FAILED_INTERNAL_ERROR` (themecenter). Fallback: `pm disable-user --user 0`. Some (themecenter) are fully protected ("Cannot disable a protected package") — leave them.
- `pm uninstall --user 0` can return "Success" while the package re-enables itself (e.g. GOS, re-added by Game Booster). Verify the real state after each batch; use `disable-user` for those.
- Google Messages may be the only SMS app — check `adb shell cmd role get-role-holders android.app.role.SMS` before removing it.
- UAD lists.json: the package name lives in the `id` field, not `list`.

## Prompt for an AI agent

Paste the following into an AI agent with the phone connected and USB debugging enabled:

```
Debloat this Android device via ADB (no root). Follow this procedure:
1. Run `adb devices -l` and confirm it shows "device".
2. Read-only recon: list all packages (`pm list packages --user 0`, also `-d` and `-e`), save to files, and get make/model/version via getprop.
3. Classify against a curated UAD list into REMOVE / DISABLE / KEEP. Never remove: launcher, System UI, Knox, Google Play Services and dependencies, the SMS app, camera, the active keyboard, Find My Mobile, system update (OTA).
4. Present a plan report with a one-line justification per item and STOP for explicit approval before any change.
5. Execute with `pm uninstall --user 0` (or `pm disable-user --user 0` for protected ones), one per line, saving the removed list. Add `< /dev/null` to every `adb shell` inside loops.
6. Verify by re-listing packages and confirm each target's state.
7. Generate a rollback script (install-existing per removed, enable per disabled).
8. Report before/after counts only from the captured lists.
```

## Reference results

- S25 Edge (2026-10-18, daily phone): 74 removed + 2 disabled + 1 protected (themecenter); 588 → 514 packages; Gmail, Google Messages (SMS), Photos, SwiftKey, Teams kept.
- S22 Ultra (2026-10-19, gaming box — DeX on TV + Xbox controller): 117 removed + GOS disabled; 528 → 411 packages; DeX/Bluetooth/GPU/audio intact. Connected via wireless debugging (the USB driver would not recognize the device).

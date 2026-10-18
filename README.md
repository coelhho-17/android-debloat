# android-debloat

Remove bloat from an Android phone (Samsung/One UI or other OEM) over USB with ADB — **no root, fully reversible**.

A companion to [ruindows-debloat](https://github.com/coelhho-17/ruindows-debloat), this time for the phone. Same philosophy: analyze → present a plan → get approval → execute → verify → rollback script.

## Why it's safe

- No root, no unlocked bootloader.
- `pm uninstall --user 0` only removes the app for *your* user — the system image keeps it, so every change is reversible with one command (`pm install-existing`).
- Nothing is touched until you approve the plan.

## What it removed (reference run — Samsung S25 Edge, One UI 8.0 / Android 16)

| Result | Count |
|---|---|
| Apps removed | 74 |
| Apps disabled | 2 |
| Protected (needs root) | 1 (Theme Center — harmless) |
| Packages on user 0 | 588 → 514 |

Removed: Facebook/Meta stubs, Microsoft stub, Bixby, AR Emoji/Bixby Vision/AR, Kids Mode, Samsung telemetry/diagnostics (12), Samsung Pay/Pass/Wallet, Galaxy Store, SmartThings, Samsung Cloud, Galaxy Themes, Samsung Video, Game Tools/GOS, 22 misc Samsung bloat apps, and 8 redundant Google apps.

Kept on purpose: Gmail, Google Messages (the only SMS app), Google Photos (Google backup), SwiftKey, Teams, Link to Windows, DeX, Smart View, Quick Share — and all user-installed apps.

## Quick start

1. Install ADB on the PC:
   ```bash
   winget install --id Google.PlatformTools --exact --accept-source-agreements --accept-package-agreements
   export ADB=$(find "$LOCALAPPDATA/Microsoft/WinGet" -iname adb.exe | head -1)
   ```
2. On the phone: Settings → About phone → Software information → tap "Build number" 7 times → Developer options → enable "USB debugging".
3. Plug in, unlock, accept the "Allow USB debugging?" popup.
4. Run `adb devices -l` and confirm the device shows as `device`.

Then either follow [GUIDE.md](GUIDE.md) yourself, or hand it to an AI agent (there's a ready-made prompt at the bottom of the guide).

## Files

- [GUIDE.md](GUIDE.md) — the full reusable guide (procedure, golden rules, pitfalls, AI prompt).
- [lists/remove.txt](lists/remove.txt) — curated safe-to-remove packages (Samsung/One UI), grouped with comments.
- [lists/keep.txt](lists/keep.txt) — never-remove packages.
- [rollback.sh](rollback.sh) — rollback script template (`pm install-existing` / `pm enable`).

## Disclaimer

Debloating is reversible and no-root, but it is still a system modification. Read the guide, approve the plan for *your* device, and keep the rollback script. Some packages are device-specific — never blindly copy a list without checking against your own `pm list packages` output first.

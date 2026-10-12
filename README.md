# SuiteDock

An independent, native Rust fork of [ArtCraft Launcher](https://github.com/storytold/craft-launcher)
for installing, updating and opening the Craft App Suite. Based on upstream 0.1.3.
Not affiliated with or endorsed by the ArtCraft team.

The official launcher's grid/table views, themes, app detection, downloads, verification,
installation, update notifications and web build remain available.

## Quality of life

**Update all** runs one app at a time: download, verify, install, then start the next app.
Waiting apps show **Queued** and can be cancelled before they start. Pausing or cancelling
the current download, or an update failing, allows the remaining queue to continue. Resuming
an app adds it to the end of the queue. Individual installs and removals use the same queue.
SuiteDock's own update can be started after the app queue finishes, avoiding conflicting installers.

**Settings → Appearance → Show community and social links outside Settings** controls Discord,
general Website/GitHub links and all social pictograms in the header, footer and system tray.
They are hidden by default. The choice is saved across restarts; old settings use the new default.
Community links are always available in Settings. Each app's own source and website links remain.

All bundled graphical artwork is original to this fork. Openly licensed fonts and original code
attribution are retained. See [ATTRIBUTION.md](ATTRIBUTION.md).

SuiteDock uses its own app identity, data directories and installer GUIDs. Its self-updater checks
`ripDZL/craft-launcher`, never the official launcher's releases. Managed Craft apps still come
from their original repositories/feed. SuiteDock can coexist with the official launcher.

## Build

Needs Rust 1.90+; on Windows use the MSVC toolchain plus Visual Studio C++ Build Tools/Windows SDK.

```powershell
cargo build --release --locked -p suitedock
cargo test --workspace --locked
cargo clippy --workspace --all-targets --locked -- -D warnings
```

Run `target/release/suitedock.exe` on Windows. Put `portable.txt` alongside it for portable settings
in `SuiteDockData/`; otherwise settings use the platform's SuiteDock data directory.
`cargo xtask ci` includes format, clippy, tests and WebAssembly checks (install `wasm32-unknown-unknown`).

Windows installer/portable ZIP: `pwsh packaging/windows/package.ps1 -Arch x64` (WiX v5 required).
For a complete checked Windows build, double-click `Build-and-Run.cmd` or run
`pwsh -NoProfile -ExecutionPolicy Bypass -File ./Build-SuiteDock.ps1 -Run`.
It checks formatting, clippy, workspace tests and WebAssembly before building a portable ZIP.
On failure, `build-logs/SuiteDock_ERROR_COMPACT.txt` contains the error and recent output.
The CI workflow runs Windows/Linux tests and the web build and uploads a Windows x64 portable ZIP
with SHA256SUMS.txt after successful tests. Full release packaging remains in `release.yml`.
Windows builds are unsigned unless signing credentials are configured.

Code and SuiteDock graphics: **MIT OR Apache-2.0**. Fonts: SIL OFL 1.1.

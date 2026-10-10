# AGENTS.md: guide for AI agents and contributors

SuiteDock installs, updates and launches the **Craft App Suite** (PhotoCraft, LightCraft,
FilmCraft, DesignCraft, VectorCraft, PdfCraft, EffectCraft, WordCraft, DeckCraft, GridCraft,
CADCraft, SoundCraft). It is written in **Rust only** (no JavaScript or TypeScript): the desktop
app is native egui/eframe, and the web build is the same Rust compiled to WebAssembly (trunk +
wasm-bindgen). **No Tauri, Electron or webview shells**, ever.

The product name is always **SuiteDock** in user-facing text: UI, window titles, About,
tray menu, notifications, installers, release names, docs prose. This is an independent fork, not an official ArtCraft product. The suite is the **Craft App
Suite**. Machine names stay lowercase: crates and binaries (`suitedock`,
`suitedock-*`), file names, and the app id `io.github.ripdzl.suitedock`. Note the
GitHub repo is `ripDZL/craft-launcher`, while every file and package is `suitedock-*`.

Standards and learnings shared across the Craft apps live in `../craftrules` (read its
`README.md` and `AGENTS.md`). Contribute reusable learnings there, never code.

## 1. Workspace map

```text
crates/
  core      suitedock-core      pure and wasm-safe: the app catalog, versions, GitHub
                                        release parsing, picking the right asset per platform
  native    suitedock-native    desktop only: HTTP, detecting installed apps, download,
                                        verify and install
  ui-egui   suitedock-ui-egui   the shared egui UI (desktop and web)
apps/
  suitedock                     desktop shell (eframe): window, tray icon, notifications
  suitedock-web                 the same UI in the browser (trunk; catalog and downloads only)
xtask/                                  cargo xtask ci | wasm | version | ico
packaging/                              macOS, Windows, Linux, FreeBSD and web packaging scripts
assets/app-icon/                        the launcher's own icon (master SVG, renders, tray icons)
assets/app-icons/                       original category icons for the managed Craft apps
assets/fonts/                           Archivo, Inter, Geist Mono (OFL-1.1): getartcraft.com's faces
```

Layering: `core` depends on no other workspace crate and must build for `wasm32-unknown-unknown`.
`native` may use `core`. `ui-egui` may use `core` (and `native` only behind
`cfg(not(target_arch = "wasm32"))` or through a trait the desktop shell implements). Nothing below
the apps opens windows, tray icons or notifications.

## 2. Golden rules

### Never crash (outranks feature work)

A bad network response, a malformed release, a half-downloaded file, a full disk or a corrupt
settings file must produce an error the user can act on, never a panic. Shared standard:
`../craftrules/standards/never-crash.md`.

- **Non-test code never panics.** No `unwrap()`, `expect()`, `panic!`, `unreachable!`, `todo!` or
  `unimplemented!`. Return the crate's error type and propagate with `?`.
- Every production crate root (`lib.rs`, each binary's `main.rs`, and `xtask`) carries
  `#![deny(clippy::unwrap_used, clippy::expect_used, clippy::panic, clippy::unimplemented, clippy::todo, clippy::unreachable)]`.
- **No `unsafe`.** The workspace sets `unsafe_code = "forbid"`.
- **Everything from the network is hostile.** Use `get()` instead of indexing, checked arithmetic
  for sizes and offsets, and cap downloads and JSON sizes.

### Installing other people's software safely

- Download only from `https://github.com/storytold/<app>/releases` (and GitHub's asset CDN).
- Verify each download against the release's `SHA256SUMS.txt` before running or installing it.
- Never run an installer with elevated rights silently; tell the user what is about to happen.
- Never delete a user's files outside what the launcher itself installed.

### Look and feel

The UI matches the apps page on getartcraft.com (`artcraft-website-next` in `artcraft-services`):
hard square corners, 1 px hairlines instead of shadows, Archivo (620, 118 % width) for headings
and app names, Inter for body text, upper-case Geist Mono labels and buttons, and the site's
colour tokens by name (`theme::Tokens`). Build new UI from `widgets.rs`; never hard-code a colour.

### Other rules

1. **Assets need attribution.** Keep ATTRIBUTION.md current. SuiteDock graphics are original
   MIT OR Apache-2.0 assets; do not reintroduce upstream marks, mascots or service logos.
2. **Icons are generated.** Edit original SVGs, then regenerate via packaging/icons.sh or
   packaging/render-icons.ps1. Managed apps retain their upstream package identities.
3. **Never break wasm.** `cargo xtask wasm` must pass. File-system, process and OS code is
   `cfg(not(target_arch = "wasm32"))`.
4. **Tests are the gate.** Release parsing and asset picking in `core` get unit tests with real
   GitHub release JSON fixtures (small, committed under `crates/core/tests/fixtures/`).
5. When fetching anything, use a generic `SuiteDock/<version>` User-Agent and never put
   a person's name, email or other personal details in requests.

## 3. Before you finish a task

```sh
cargo xtask ci              # fmt --check, clippy -D warnings, test, wasm check
```

Or piecemeal: `cargo test -p <crate>`, `cargo clippy -p <crate> --all-targets -- -D warnings`,
`cargo xtask wasm`. If you touched packaging: `shellcheck packaging/*.sh packaging/*/*.sh
packaging/linux/AppRun` and `actionlint`.

## 4. Releasing

The version lives only in `[workspace.package] version` in the root `Cargo.toml`
(`cargo xtask version`, `cargo xtask version set X.Y.Z[-pre]`). Pushing to the `release` branch runs
`.github/workflows/release.yml`, which builds every platform and creates the draft GitHub Release
**SuiteDock v<version>** with `SHA256SUMS.txt`. The canonical recipe is
`../craftrules/release/playbook.md`; cutting a release is `../craftrules/release/cut-a-release.md`.

Release assets (keep these names exact; the launcher's own self-update and the README rely on them):

| Platform | Files |
|---|---|
| Windows | `suitedock-<ver>-windows-{x64,x86,arm64}.msi`, `…-windows-{x64,x86,arm64}-portable.zip` |
| macOS | `suitedock-<ver>-macos-universal.dmg` |
| Linux | `suitedock-<ver>-linux-{x86_64,aarch64}.{AppImage,AppImage.zsync,deb,rpm,tar.gz,flatpak}` |
| FreeBSD | `suitedock-<ver>-freebsd-x86_64.tar.gz` |
| Web | `suitedock-web-<ver>.zip` |

Packaging facts the code relies on:

- The Windows MSI is **per-user** (no UAC prompt), by default into
  `%LOCALAPPDATA%\Programs\SuiteDock`. Double-clicked it opens a WixUI setup wizard
  (Welcome; a folder page with a "Create a desktop shortcut" box; Ready; progress; Finish with
  "Launch"), whose art `package.ps1` draws at build time; self-update runs it with `/passive`, no
  wizard. The folder and the shortcut choice are recorded under
  `HKCU\Software\ripDZL\SuiteDock` (`InstallDir`,
  `DesktopShortcutChoice`) and reused by the next version, and `self_update.rs` reads `InstallDir`
  to know the running copy came from the MSI. Its shortcuts set AppUserModelID
  `io.github.ripdzl.suitedock`, which toast notifications need. `portable.txt` beside the exe switches on portable mode
  (`SuiteDockData\` next to the exe).
- The macOS bundle is `SuiteDock.app` (executable `Contents/MacOS/SuiteDock`), a
  normal Dock app that can also sit in the menu bar: `LSUIElement` must never be set.
- Linux: the tray uses StatusNotifierItem over D-Bus and notifications use
  `org.freedesktop.Notifications`, both in pure Rust (no GTK, appindicator or libdbus).
- `build.rs` reads `SUITEDOCK_BUILD_SHA` / `SUITEDOCK_BUILD_DATE` and, on Windows,
  embeds `assets/app-icon/suitedock.ico`, failing the build when
  `SUITEDOCK_REQUIRE_WINRES=1` and it can't.

## 5. Parallel agents

- Use your own target dir (`CARGO_TARGET_DIR=target/agent-<name>`) and edit only the files you own.
- Keep every `Cargo.toml` valid at all times: the `crates/*` and `apps/*` globs mean one broken
  manifest breaks everyone's build. Write manifests to a temp file and `mv` them into place.
- If someone else's in-progress edit breaks the build, wait and retry; don't fix their files.

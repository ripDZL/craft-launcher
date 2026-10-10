# SuiteDock project state

2026-10-10: independent fork at ripDZL/craft-launcher, based on upstream release 0.1.3
(3a1140e949e6e0a79d2eae5587dd5909b0cb0f60). Working version 0.1.4-beta.1.

User requirements: keep the official native Rust launcher and its functions; add a saved hide/show
control for all social/community shortcuts outside Settings; replace protected graphics with our own.

Implemented: show_social_links defaults false, serde-compatible with older settings; header/footer
and tray follow it; Settings retains all links; per-app links remain. Original SVG mark/wordmark,
twelve category icons and generic social pictograms replace upstream graphics. OFL fonts remain
with their licenses. SuiteDock has separate app/data/registry/MSI identities. Only launcher updates
use ripDZL/craft-launcher; suite app updates still use upstream. The feed cannot rename our updater.

Verification on 2026-10-10: formatting and workspace Clippy with -D warnings passed. All 92
workspace tests passed (2 existing tests ignored), including 18 UI interaction tests. Native
loopback HTTP tests required SSL_CERT_FILE pointing to the session's certifi CA bundle because
the sandbox account's certificate store was empty; production TLS verification was unchanged.
The Windows x64 release build passed with static CRT and required icon resources. Original SVG
rendering and Windows shortcut validation passed. Three unnecessary dereferences in the UI
tests were removed after the user's first build reported clippy::explicit_auto_deref.
The core wasm check passed; the web check could not finish because uncached dependencies could
not be downloaded. Do not report the complete web build or GitHub CI as passing until verified.
CI checks Windows/Linux and the web build and uploads a Windows x64 portable ZIP with checksums.
GitHub write access was verified after the user updated access. Publishing targets beta with a
non-forced, expected-head update; main and the earlier dirty checkout remain untouched.

The earlier dirty checkout at C:\Users\Admin\Documents\ArtCraft-Launcher-Beta\craft-launcher
has been preserved. Do not apply broad textual patches there or overwrite its uncommitted work.

Next changes should read live source and this file first. Preserve layouts, all controls, themes,
install/detection/update behavior, release checksums, and the web build. No Electron/webview.

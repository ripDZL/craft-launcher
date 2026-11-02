# SuiteDock beta refresh — November 2, 2026

This staging source is rebased onto upstream `storytold/craft-launcher` main at commit
`ec205366ebe42635e155b9ab246f036052fef406` (workspace v0.13.0). It is not a
validated release: GitHub Actions has not yet produced results for the November 2 merge.

## New upstream functionality

- All upstream changes since the October 30 v0.10 snapshot, including the new TextureCraft
  and Craft Anything catalog entries, release/install reliability improvements, the MSI
  batch refactor, additional macOS verification, updated queues, pinning and recovery.
- Upstream dependency updates and the 0.13.0 Cargo.lock.
- Current Linux, Windows, macOS, FreeBSD and wasm/web sources and packaging updates.

## SuiteDock customization

- SuiteDock name, icon, app ID `io.github.ripdzl.suitedock`, data folders and release identity.
- `suitedock` and `suitedock-web` Cargo package/binary names.
- Persistent setting to hide Website, GitHub, Discord and general community/social links in the
  footer and tray while keeping them reachable in Settings. Hidden by default.
- Fork release updates check `ripDZL/craft-launcher`.
- Old custom fork FIFO queue not retained: current upstream queue is used.

## Validation status

The October 30 build passed main CI, Windows ARM64, Nix, packaging lint and SonarCloud, but
failed one FreeBSD-only test whose target code was replaced by newer upstream.
All November 2 source changes require fresh CI on all platforms; do not publish an installer
until the validation matrix is green. Native Windows and macOS installations also require
their own smoke tests.

## Asset licensing review

The new upstream `assets/app-icons/craft-anything.png` is identified by upstream as a
non-open-source brand asset. Review its upstream license and redistribution permission before
publishing SuiteDock binaries or redistributing that icon. The fork's own SuiteDock artwork
remains MIT OR Apache-2.0.

# SuiteDock beta refresh — October 30, 2026

This beta is rebuilt on the current `storytold/craft-launcher` main branch and keeps the fork-specific
SuiteDock identity and preferences on top of the newer upstream installer/update engine.

## Upstream carried forward

- Workspace version 0.10.0 plus upstream main maintenance through October 30, 2026.
- Current install/update queue and recovery behavior.
- Version selection, pinning and downgrade support.
- Updated egui/UI, language support, portable-suite controls and release-feed hardening.
- Current Windows, Linux, macOS, FreeBSD and web packaging logic.
- Current app catalog, including FigCraft and approved community-app support.

## SuiteDock-specific behavior retained

- Independent SuiteDock name, application id, executable/package names, data paths and artwork.
- Upstream ArtCraft Launcher trademark artwork is not distributed by this fork.
- The ArtCraft/Craft App Suite links remain where they identify the upstream community and apps.
- A persistent **Show community and social links outside Settings** preference is available.
  It defaults off, hiding general Website/GitHub/Discord/social links from the footer and tray.
  The same community links always remain available in Settings.
- Fork self-update metadata points at `ripDZL/craft-launcher`.

## Intentional change from the older beta

The fork's earlier custom FIFO install queue was not ported. Upstream now has a newer and more
complete queue/install implementation, including waiting/cancellation/recovery behavior. Keeping
the old queue would duplicate and conflict with current upstream logic.

## Validation

GitHub Actions is the release gate for this branch: formatting, clippy, unit/integration tests,
wasm/trunk build, packaging policy checks, Nix, Windows ARM64, FreeBSD and SonarCloud.

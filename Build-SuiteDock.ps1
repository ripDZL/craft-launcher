param([switch]$Run, [switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($PSScriptRoot)
$LogDir = Join-Path $Root 'build-logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Log = Join-Path $LogDir ('build-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
Start-Transcript -LiteralPath $Log | Out-Null
function Native([string]$Label, [scriptblock]$Command) {
    Write-Host "`n==> $Label"
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Label failed (exit $LASTEXITCODE)." }
}
$Previous = Get-Location
try {
    Set-Location -LiteralPath $Root
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) { throw 'Rust is missing. Install the stable MSVC toolchain from https://rustup.rs/ and reopen PowerShell.' }
    if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) { throw 'rustup is missing. This build uses the stable MSVC toolchain from https://rustup.rs/.' }
    $Info = rustc -vV
    if (($Info -join "`n") -notmatch 'host: x86_64-pc-windows-msvc') { throw 'Use the x86_64-pc-windows-msvc Rust toolchain for this Windows x64 build.' }
    $Version = (& cargo xtask version).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the workspace version.' }
    Write-Host "SuiteDock $Version - native Windows x64 build"
    Write-Host 'Needs Visual Studio C++ Build Tools and Windows SDK. First build downloads dependencies.'
    if (-not $SkipChecks) {
        Native 'Install WebAssembly target' { rustup target add wasm32-unknown-unknown }
        Native 'Install formatter and clippy' { rustup component add rustfmt clippy }
        Native 'Format check' { cargo fmt --all -- --check }
        Native 'Clippy' { cargo clippy --workspace --all-targets --locked -- -D warnings }
        Native 'Workspace tests' { cargo test --workspace --locked }
        Native 'WebAssembly check' { cargo xtask wasm }
        & (Join-Path $Root 'packaging/windows/check-icons.ps1')
    }
    $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS = '-C target-feature=+crt-static'
    $env:SUITEDOCK_REQUIRE_WINRES = '1'
    $env:SUITEDOCK_BUILD_DATE = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
    Native 'Release build' { cargo build --release --locked -p suitedock --target x86_64-pc-windows-msvc }
    $Dist = Join-Path $Root 'dist'
    $Portable = Join-Path $Dist "suitedock-$Version-windows-x64-portable"
    New-Item -ItemType Directory -Force -Path $Portable | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root 'target/x86_64-pc-windows-msvc/release/suitedock.exe') -Destination $Portable
    Copy-Item -LiteralPath (Join-Path $Root 'packaging/windows/portable.txt') -Destination $Portable
    foreach($file in @('LICENSE-MIT','LICENSE-APACHE','NOTICE','ATTRIBUTION.md','README.md')) { Copy-Item -LiteralPath (Join-Path $Root $file) -Destination $Portable }
    $FontLicenses = Join-Path $Portable 'font-licenses'
    New-Item -ItemType Directory -Force -Path $FontLicenses | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $Root 'assets/fonts') -Filter 'OFL-*.txt' | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $FontLicenses }
    # Explicit file list excludes any portable settings from a previous run.
    $Archive = Join-Path $Dist "suitedock-$Version-windows-x64-portable.zip"
    $Files = @(Get-ChildItem -LiteralPath $Portable -File | ForEach-Object { $_.FullName }) + @($FontLicenses)
    Compress-Archive -LiteralPath $Files -DestinationPath $Archive -Force
    $Hash = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
    "$Hash  $([IO.Path]::GetFileName($Archive))" | Set-Content -LiteralPath (Join-Path $Dist 'SHA256SUMS.txt') -Encoding utf8
    Write-Host "`nReady: $Archive"
    if ($Run) { Start-Process -FilePath (Join-Path $Portable 'suitedock.exe') }
} catch {
    $Compact = Join-Path $LogDir 'SuiteDock_ERROR_COMPACT.txt'
    @(
        "Time: $((Get-Date).ToString('o'))",
        "Error: $($_.Exception.Message)",
        "Location: $($_.InvocationInfo.PositionMessage)",
        'Recent output:',
        (Get-Content -LiteralPath $Log -Tail 65 -ErrorAction SilentlyContinue)
    ) | Set-Content -LiteralPath $Compact -Encoding utf8
    Write-Host "`nBUILD FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Compact log: $Compact"
    exit 1
} finally {
    Set-Location -LiteralPath $Previous.Path
    Stop-Transcript | Out-Null
}

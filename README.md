# Market Coin Farmer — Enhanced

Private Windows x64 maintenance build of [Market Coin Farmer](https://github.com/xob0t/market-coin-farmer) by xob0t. This is an unofficial modification, not an official Yandex product.

## Enhanced V3

- Compatibility with the observed November 2026 Market version format.
- Windows DPAPI (CurrentUser) protection of stored account configuration.
- Removal of direct account-object logging and improved notification contrast.
- Safer account editing and duplicate detection.
- Automated build and regression checks; local npm audits reported zero known findings on 27 November 2026.

## Build and recovery

Base commit: `27b6c1a0750c4bd595b565a3c14c5000455f3314`.

Local tools used: Go 1.27.4, Node.js 26.13.1, npm 11.20.0, Wails v3.0.0-beta.5, Task 3.54.0, Git and WebView2. Extract the V3 builder archive and run BUILD.bat without administrator privileges. Keep the audited lockfile for future builds. The ready-to-use executable and V3 builder archive are available in the [v1.3.0-enhanced.3 release](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/tag/v1.3.0-enhanced.3). The audited lockfile and audit reports are stored in `recovery/`. The builder resolves security updates again when rebuilding, so future builds may differ from this release.

## Security and rights

Never upload config.dpapi, config.yaml, session cookies or proxy credentials. DPAPI is bound to the Windows user context and does not protect against every process running as that user. Zero npm audit findings are not a guarantee of safety. Automation may be restricted by service rules.

Upstream has no declared license identified during review; this private repository is for personal maintenance. Do not redistribute upstream code or binaries without permission.

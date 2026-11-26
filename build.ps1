# Windows PowerShell 5.1+, ordinary user. No admin rights required.
param([string]$LegacyFolder = '', [switch]$NoImport)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$commit = '27b6c1a0750c4bd595b565a3c14c5000455f3314'
$repo = 'https://github.com/xob0t/market-coin-farmer.git'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$root = $PSScriptRoot
$work = $null
$stage = $null
$exitCode = 0

function Step([string]$Message) { Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Run([string]$Exe, [string[]]$Arguments) {
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Exe failed (exit $LASTEXITCODE)." }
}
function Read-Text([string]$Path) { return [IO.File]::ReadAllText($Path).Replace("`r`n", "`n") }
function Write-Text([string]$Path,[string]$Text) { [IO.File]::WriteAllText($Path,$Text,$utf8) }
function Replace-Once([string]$Text,[string]$Old,[string]$New,[string]$Name) {
    $Old = $Old.Replace("`r`n", "`n")
    $New = $New.Replace("`r`n", "`n")
    $first = $Text.IndexOf($Old,[StringComparison]::Ordinal)
    if ($first -lt 0 -or $Text.IndexOf($Old,$first+$Old.Length,[StringComparison]::Ordinal) -ge 0) { throw "Patch anchor mismatch: $Name" }
    return $Text.Substring(0,$first) + $New + $Text.Substring($first+$Old.Length)
}
function Replace-Line([string]$Text,[string]$Pattern,[string]$New,[string]$Name) {
    $hits = [regex]::Matches($Text,$Pattern)
    if ($hits.Count -ne 1) { throw "Patch anchor mismatch: $Name" }
    return (Replace-Once $Text ($hits[0].Value) $New $Name)
}
function Audit([string]$File,[string[]]$Flags) {
    $argsList = @('audit','--json') + $Flags
    $lines = & npm.cmd @argsList
    $code = $LASTEXITCODE
    Write-Text $File ($lines -join "`n")
    try {
        $data = Get-Content -LiteralPath $File -Raw | ConvertFrom-Json
        $v = $data.metadata.vulnerabilities
        if ($null -eq $v -or $null -eq $v.total) { throw 'Missing vulnerability counts' }
        Write-Host "Audit: total=$($v.total), high=$($v.high), critical=$($v.critical), exit=$code"
        if ([int]$v.total -ne 0 -or $code -ne 0) { throw 'Audit not clean' }
    } catch { throw "Audit gate failed: $File. $($_.Exception.Message)" }
}

try {
    Step 'Checking existing tools'
    foreach ($tool in @('git','go','gofmt','node','npm.cmd','wails3','task')) {
        if ($tool -eq 'wails3' -or $tool -eq 'task') { continue }
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Missing tool: $tool" }
    }
    $gopath = (& go env GOPATH | Select-Object -First 1).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'go env GOPATH failed' }
    $gobin = (& go env GOBIN | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0) { throw 'go env GOBIN failed' }
    if (-not [string]::IsNullOrWhiteSpace($gobin)) { $env:Path += ';' + $gobin.Trim() }
    $env:Path += ';' + (Join-Path ($gopath.Split(';')[0]) 'bin')
    foreach ($tool in @('wails3','task')) { if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Missing tool: $tool" } }
    # Wails can print its version directly to the Windows console rather than
    # PowerShell's success stream. Inspect the Go module metadata of the actual
    # executable resolved by PATH instead of capturing its console output.
    $wailsExe = (Get-Command wails3 -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $wailsInfo = (& go version -m $wailsExe | Out-String).Trim()
    $wailsInfoExit = $LASTEXITCODE
    $wailsPattern = '(?m)^[ \t]*mod[ \t]+github\.com/wailsapp/wails/v3[ \t]+([^ \t\r\n]+)'
    $wailsModule = [regex]::Match($wailsInfo,$wailsPattern)
    if ($wailsInfoExit -ne 0 -or -not $wailsModule.Success) {
        throw "Cannot verify Wails module metadata for $wailsExe. Run: go version -m `"$wailsExe`""
    }
    $wails = $wailsModule.Groups[1].Value
    if ($wails -ne 'v3.0.0-beta.5') { throw "Expected Wails v3.0.0-beta.5; found $wails at $wailsExe" }
    Write-Host "Wails verified: $wails ($wailsExe)"
    $goVersion = (& go version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $goVersion -notmatch '\bgo1\.(\d+)' -or [int]$Matches[1] -lt 26) { throw 'Go 1.26 or newer is required' }
    Run git @('--version'); Write-Host $goVersion; Run node @('--version'); Run npm.cmd @('--version'); Run task @('--version')
    if ([Environment]::Is64BitOperatingSystem -eq $false) { throw 'Windows x64 is required' }
    $env:GOOS = 'windows'; $env:GOARCH = 'amd64'; $env:CGO_ENABLED = '0'

    $desktop = [Environment]::GetFolderPath('DesktopDirectory')
    if ([string]::IsNullOrWhiteSpace($LegacyFolder)) {
        $knownV2 = 'D:\Desktop\Market Coin Farmer - Improved 20261127-002306-e6c38a'
        if (Test-Path -LiteralPath $knownV2 -PathType Container) {
            $LegacyFolder = $knownV2; $desktop = 'D:\Desktop'
        } elseif (-not $NoImport) {
            throw 'V2 folder not found. Pass -LegacyFolder with the current installation path, or -NoImport.'
        }
    }
    if (-not (Test-Path -LiteralPath $desktop -PathType Container)) { throw 'Desktop folder not found' }
    if ([string]::IsNullOrWhiteSpace($LegacyFolder)) { $LegacyFolder = $desktop }
    $legacyConfig = Join-Path $LegacyFolder 'config.yaml'
    $legacyEncrypted = Join-Path $LegacyFolder 'config.dpapi'
    if (-not $NoImport -and -not (Test-Path -LiteralPath $legacyEncrypted -PathType Leaf)) { throw 'Encrypted V2 config not found. Specify the working V2 folder or -NoImport.' }
    $buildId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + ([guid]::NewGuid().ToString('N').Substring(0,6))
    $work = Join-Path $env:LOCALAPPDATA ('MCFBuilder\' + $buildId)
    New-Item -ItemType Directory -Path $work | Out-Null
    $source = Join-Path $work 'source'

    Step 'Fetching reviewed source commit'
    Run git @('clone','--no-checkout',$repo,$source)
    Set-Location -LiteralPath $source
    Run git @('checkout','--detach',$commit)
    $actual = (& git rev-parse HEAD | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $actual -ne $commit) { throw 'Unexpected source commit' }

    Step 'Applying compatibility and security changes'
    $p = Join-Path $source 'yaapisservice.go'; $s = Read-Text $p
    $s = Replace-Line $s '(?m)^[ \t]*appVersionRegex[ \t]*=.*$' '    appVersionRegex = regexp.MustCompile(`"-version"\s*:\s*"((?:mf-promoloyalty\.)?\d{4}\.\d{2}\.\d{2}[^"]*)"`)' 'appVersionRegex'
    Write-Text $p $s
    $p = Join-Path $source 'yaapi_transport.go'; $s = Read-Text $p
    $s = Replace-Once $s 'return fmt.Errorf("market request context is missing")' 'return fmt.Errorf("market request context is missing: AppVersion=%t, FrontGlue=%t", account.AppVersion != "", account.FrontGlue != "")' 'safe diagnostics'
    Write-Text $p $s
    foreach ($file in @('configservice.go','dpapi_windows.go','mcf_hardening_test.go')) {
        Copy-Item -LiteralPath (Join-Path $root ('patches\' + $file)) -Destination (Join-Path $source $file) -Force
    }

    $p = Join-Path $source 'browserauthservice.go'; $s = Read-Text $p
    $s = Replace-Once $s 'chromedp.Flag("no-default-browser-check", true),' ('chromedp.Flag("no-default-browser-check", true),' + "`n`t`tchromedp.Flag(`"disable-sync`", true),") 'browser sync'
    $s = Replace-Once $s 'strings.Contains(cookie.Domain, "yandex")' 'isMCFYandexDomain(cookie.Domain)' 'session domain'
    $s = Replace-Once $s 'if cookie.Name == "" {' 'if cookie.Name == "" || !isMCFYandexDomain(cookie.Domain) {' 'cookie filtering'
    $s = Replace-Once $s 'if cookie.Name == "yandex_login" && cookie.Value != "" {' 'if cookie.Name == "yandex_login" && cookie.Value != "" && isMCFYandexDomain(cookie.Domain) {' 'login domain'
    $s += @'

func isMCFYandexDomain(domain string) bool {
    domain = strings.Trim(strings.ToLower(domain), ".")
    for _, allowed := range []string{"yandex.ru", "yandex.net", "yandex.com", "ya.ru"} {
        if domain == allowed || strings.HasSuffix(domain, "."+allowed) { return true }
    }
    return false
}
'@
    Write-Text $p $s

    $p = Join-Path $source 'frontend\src\components\AccountManager.vue'; $s = Read-Text $p
    foreach ($line in @('      console.log(newAccount)','    console.log(account)','      console.log(updatedAccount)','    await ConfigService.RemoveAccountFromConfig(oldAccount)')) {
        $s = Replace-Once $s ($line+"`n") '' 'remove sensitive log / unsafe edit'
    }
    $old = @'
    await ConfigService.AddAccountToConfig(account)

    // Update data reference if cookies changed
'@
    $new = @'
    await ConfigService.UpdateAccountInConfig(oldAccount, account)

    // Update data reference if cookies changed
'@
    $s = Replace-Once $s $old $new 'single-write account update'
    $s = Replace-Once $s 'if (oldAccount.cookies !== account.cookies && accountsData[oldAccount.cookies]) {' 'if (oldAccount.cookies !== btoa(account.cookies) && accountsData[oldAccount.cookies]) {' 'encoded cookie comparison'
    $s = Replace-Once $s 'accountsData[account.cookies] = accountsData[oldAccount.cookies]' 'accountsData[btoa(account.cookies)] = accountsData[oldAccount.cookies]' 'encoded cookie state'
    $s = [regex]::Replace($s,'(?m)^\s*console\.error\(err\)\r?\n','')
    $s = Replace-Once $s "{{ account.proxy || 'Нет' }}" "{{ account.proxy ? 'Настроен' : 'Нет' }}" 'hide proxy credentials'
    Write-Text $p $s
    $p = Join-Path $source 'frontend\src\App.vue'; $s = Read-Text $p
    $s = Replace-Once $s '<Toaster />' '<Toaster theme="dark" />' 'dark notifications'
    Write-Text $p $s
    $p = Join-Path $source 'frontend\src\index.css'; $s = Read-Text $p
    $s += "`n/* MCF: readable toast text on the dark theme. */`n.dark [data-sonner-toast] [data-description] { color: #d4d4d8 !important; }`n"
    Write-Text $p $s
    $p = Join-Path $source 'build\Taskfile.yml'; $s = Read-Text $p
    $s = Replace-Once $s '      - npm install' '      - npm ci --ignore-scripts --no-audit' 'locked npm dependencies'
    Write-Text $p $s
    Run gofmt @('-w','yaapisservice.go','yaapi_transport.go','configservice.go','dpapi_windows.go','browserauthservice.go','mcf_hardening_test.go')
    Run git @('diff','--check')

    Step 'Updating vulnerable npm dependencies within declared ranges'
    Set-Location -LiteralPath (Join-Path $source 'frontend')
    # No --force, no lifecycle scripts, no arbitrary version overrides.
    # npm can return 1 when advisories remain; the independent audit below is authoritative.
    $fixLines = & npm.cmd audit fix --package-lock-only --ignore-scripts --json
    $fixCode = $LASTEXITCODE
    Write-Text (Join-Path $work 'npm-audit-fix.json') ($fixLines -join "`n")
    Write-Host "npm audit fix exit: $fixCode"
    if ($fixCode -notin @(0,1)) { throw 'npm audit fix failed' }
    Run npm.cmd @('ci','--ignore-scripts','--no-audit')
    Step 'Checking updated dependencies before building'
    Audit (Join-Path $work 'npm-audit-all.json') @()
    Audit (Join-Path $work 'npm-audit-production.json') @('--omit=dev')
    Set-Location -LiteralPath $source
    Run git @('diff','--check')

    Step 'Building Windows executable' 
    Run task @('common:update:build-assets')
    Run task @('windows:build')
    $exe = Join-Path $source 'bin\market-coin-farmer.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'No executable produced' }
    Step 'Verifying Go modules and running offline regression tests'
    Run go @('mod','verify')
    Run go @('test','-count=1','-run','^TestMCF','.')

    Step 'Final dependency security gate'
    Set-Location -LiteralPath (Join-Path $source 'frontend')
    Audit (Join-Path $work 'npm-audit-all.json') @()
    Audit (Join-Path $work 'npm-audit-production.json') @('--omit=dev')
    Set-Location -LiteralPath $source
    Copy-Item -LiteralPath (Join-Path $source 'frontend\package-lock.json') -Destination (Join-Path $work 'package-lock.v3.json')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $exe).Hash

    Step 'Staging independent desktop installation'
    $dest = Join-Path $desktop ('Market Coin Farmer - V3 ' + $buildId)
    $stage = Join-Path $desktop ('.mcf-stage-' + $buildId)
    New-Item -ItemType Directory -Path $stage | Out-Null
    Copy-Item -LiteralPath $exe -Destination (Join-Path $stage 'market-coin-farmer.exe')
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $stage 'market-coin-farmer.exe')).Hash -ne $hash) { throw 'Copied EXE hash mismatch' }
    $imported = 'no'
    if (-not $NoImport -and ((Test-Path -LiteralPath $legacyConfig -PathType Leaf) -or (Test-Path -LiteralPath $legacyEncrypted -PathType Leaf))) {
        while (Get-Process -Name 'market-coin-farmer*' -ErrorAction SilentlyContinue) {
            Write-Host 'Close ALL Market Coin Farmer windows. Press Enter to check again, or Q to cancel.' -ForegroundColor Yellow
            Get-Process -Name 'market-coin-farmer*' -ErrorAction SilentlyContinue | Select-Object Id,Path | Format-Table -AutoSize | Out-Host
            if ((Read-Host) -eq 'Q') { throw 'Installation cancelled. Existing files untouched.' }
        }
        Add-Type -AssemblyName System.Security
        $plain = $null
        try {
            if (Test-Path -LiteralPath $legacyEncrypted -PathType Leaf) {
                $plain = [Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes($legacyEncrypted),$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
            } else { $plain = [IO.File]::ReadAllBytes($legacyConfig) }
            if ($plain.Length -eq 0) { throw 'Old configuration is empty' }
            $sealed = [Security.Cryptography.ProtectedData]::Protect($plain,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
            [IO.File]::WriteAllBytes((Join-Path $stage 'config.dpapi'),$sealed)
            $imported = 'yes'
        } finally { if ($null -ne $plain) { [Array]::Clear($plain,0,$plain.Length) } }
    } else { Write-Host 'No old configuration imported; sign in manually if needed.' }
    Write-Text (Join-Path $stage 'build-info.txt') ("Source commit: $commit`nSHA256: $hash`nConfiguration imported: $imported`nReports and source: $work`nOffline regression tests: passed`nNpm audit all: 0`nNpm audit production: 0`n")
    Move-Item -LiteralPath $stage -Destination $dest
    $stage = $null
    Step 'BUILD SUCCESS'
    Write-Host "New application: $dest" -ForegroundColor Green
    Write-Host "Audit reports and build source: $work"
    Write-Host 'The old installation and original config were NOT changed. Test the new application before deleting them.'
    Write-Host 'DPAPI protects data at rest for the current Windows user; it is not protection from malware running as that user.'
    Start-Process explorer.exe -ArgumentList ('"'+$dest+'"')
} catch {
    $exitCode = 1
    Write-Host "`nBUILD FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($work) { Write-Host "Build files kept: $work" }
    if ($stage) { Write-Host "Incomplete staging folder (not a finished installation): $stage" }
    Write-Host 'No old installation was overwritten or removed.'
} finally {
    Set-Location -LiteralPath $root
}
exit $exitCode

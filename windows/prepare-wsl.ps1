<#
.SYNOPSIS
Prepares a Windows machine for linux-land: WSL 2, the Ubuntu release, .wslconfig and
/etc/wsl.conf, then clones linux-land inside the distro and runs setup.sh.

.DESCRIPTION
Safe to re-run: each step checks first and only does what is missing.

  1. Installs WSL when it is missing (needs an elevated PowerShell and a restart; run
     the script again afterwards), updates it, and makes WSL 2 the default.
  2. Installs the distro (default Ubuntu-24.04, or the release a machine snapshot was
     taken on). You create your Linux user in the window that opens, then type exit.
  3. Writes %USERPROFILE%\.wslconfig if there is none: memory = RAM minus 8 GB, so a
     large local model fits, and autoMemoryReclaim=gradual plus sparseVhd=true, so
     the VM hands memory and disk back to Windows after big copies or downloads.
  4. Writes /etc/wsl.conf in the distro if it lacks systemd: systemd on (snap, cron
     and user services need it), your user as the default.
  5. Restarts WSL, clones linux-land into ~/git/JB0t/linux-land and runs
     setup.sh (it asks for your sudo password).

Then, to copy another machine's packages: put that machine's snapshot bundle in
place (see machines/ in the README) and run `machine diff` and `machine restore`.

.PARAMETER Distro
WSL distro to install, e.g. Ubuntu-24.04. Defaults to the snapshot's release, else
Ubuntu-24.04.

.PARAMETER Snapshot
A machines/NAME/manifest.json from linux-land, to install the same Ubuntu release.

.PARAMETER MemoryGB
Memory for the WSL VM in .wslconfig. Default: total RAM minus 8 GB (at least 4).

.PARAMETER ReplaceWslConfig
Replace an existing .wslconfig (it is backed up to .wslconfig.bak.<time> first).

.PARAMETER NerdFont
Also install this Nerd Font for Windows Terminal, e.g. JetBrainsMono (from the
ryanoasis/nerd-fonts releases). nvim's icons need one.

.PARAMETER SkipSetup
Stop after preparing WSL, without cloning linux-land or running setup.sh.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\prepare-wsl.ps1

.EXAMPLE
.\prepare-wsl.ps1 -Snapshot .\manifest.json -NerdFont JetBrainsMono
#>
[CmdletBinding()]
param(
    [string]$Distro = "",
    [string]$Snapshot = "",
    [int]$MemoryGB = 0,
    [switch]$ReplaceWslConfig,
    [string]$NerdFont = "",
    [string]$RepoUrl = "https://github.com/JB0t/linux-land.git",
    [string]$RepoDir = "~/git/JB0t/linux-land",
    [switch]$SkipSetup
)

$ErrorActionPreference = "Stop"
# wsl.exe writes UTF-16 by default, which PowerShell reads as text with gaps.
$env:WSL_UTF8 = "1"

function Write-Step([string]$Text) { Write-Host "==> $Text" -ForegroundColor Cyan }

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Runs a script inside the distro without quoting trouble: it travels as base64 and
# is written to a file first, so the script keeps the terminal for sudo prompts.
function Invoke-InDistro([string]$Script, [string]$User = "") {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($Script -replace "`r", ""))
    $encoded = [Convert]::ToBase64String($bytes)
    $userArgs = @()
    if ($User) { $userArgs = @("-u", $User) }
    & wsl.exe -d $Distro @userArgs -- sh -c "echo $encoded | base64 -d > /tmp/linux-land-step.sh"
    & wsl.exe -d $Distro @userArgs -- bash /tmp/linux-land-step.sh
    if ($LASTEXITCODE -ne 0) { throw "step failed inside $Distro (exit $LASTEXITCODE)" }
}

# --- 1. WSL itself -------------------------------------------------------------------
Write-Step "Checking WSL"
& wsl.exe --version *> $null
if ($LASTEXITCODE -ne 0) {
    if (-not (Test-Admin)) {
        throw "WSL is not installed. Run this script once from PowerShell opened with 'Run as administrator'."
    }
    & wsl.exe --install --no-distribution
    Write-Host "WSL is installed. Restart Windows, then run this script again (no admin needed)." -ForegroundColor Yellow
    exit 0
}
& wsl.exe --update
& wsl.exe --set-default-version 2 | Out-Null

# --- 2. The distro -------------------------------------------------------------------
if (-not $Distro) {
    if ($Snapshot) {
        $manifest = Get-Content -Raw -Path $Snapshot | ConvertFrom-Json
        if ($manifest.distro.id -ne "ubuntu") { throw "the snapshot is $($manifest.distro.pretty); only Ubuntu is supported here" }
        $Distro = "Ubuntu-$($manifest.distro.version)"
    } else {
        $Distro = "Ubuntu-24.04"
    }
}
Write-Step "Checking for $Distro"
$installed = @(& wsl.exe --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($installed -notcontains $Distro) {
    Write-Host "Installing $Distro. Create your Linux user when asked, then type 'exit' to continue here."
    & wsl.exe --install -d $Distro
    if ($LASTEXITCODE -ne 0) { throw "wsl --install -d $Distro failed; 'wsl --list --online' shows the names available" }
}
$linuxUser = (& wsl.exe -d $Distro -- whoami).Trim()
if (-not $linuxUser -or $linuxUser -eq "root") {
    throw "$Distro has no normal default user yet. Run 'wsl -d $Distro', create one, then run this script again."
}

# --- 3. .wslconfig -------------------------------------------------------------------
$wslConfig = Join-Path $env:USERPROFILE ".wslconfig"
$totalGB = [math]::Floor((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($MemoryGB -le 0) { $MemoryGB = [math]::Max(4, $totalGB - 8) }
$wslConfigText = @"
# Written by linux-land's prepare-wsl.ps1. Applies after 'wsl --shutdown'.
[wsl2]
# The VM's memory ceiling ($totalGB GB in this machine); a 30B model at Q8 needs ~33 GB.
memory=${MemoryGB}GB
swap=8GB

[experimental]
# Hand memory the Linux page cache no longer needs back to Windows, a little at a time.
autoMemoryReclaim=gradual
# Shrink the virtual disk when files are deleted.
sparseVhd=true
"@
if ((Test-Path $wslConfig) -and -not $ReplaceWslConfig) {
    Write-Step ".wslconfig exists; left alone (-ReplaceWslConfig to replace it). It contains:"
    Get-Content $wslConfig | ForEach-Object { Write-Host "    $_" }
} else {
    if (Test-Path $wslConfig) {
        Copy-Item $wslConfig "$wslConfig.bak.$(Get-Date -Format yyyyMMddHHmmss)"
    }
    Write-Step "Writing $wslConfig (memory=${MemoryGB}GB of $totalGB GB)"
    Set-Content -Path $wslConfig -Value $wslConfigText -Encoding ascii
}

# --- 4. /etc/wsl.conf ----------------------------------------------------------------
Write-Step "Checking /etc/wsl.conf in $Distro"
Invoke-InDistro -User root -Script @"
set -e
if grep -qs '^systemd *= *true' /etc/wsl.conf; then
    echo '    systemd already on; /etc/wsl.conf left alone'
    exit 0
fi
[ -f /etc/wsl.conf ] && cp /etc/wsl.conf /etc/wsl.conf.bak.`$(date +%Y%m%d%H%M%S)
cat > /etc/wsl.conf <<'CONF'
# Written by linux-land's prepare-wsl.ps1
[boot]
systemd=true

[user]
default=$linuxUser

[interop]
appendWindowsPath=true
CONF
echo '    wrote /etc/wsl.conf (systemd on, default user $linuxUser)'
"@

Write-Step "Restarting WSL so the settings apply"
& wsl.exe --shutdown
Start-Sleep -Seconds 3

# --- Nerd Font for Windows Terminal ---------------------------------------------------
if ($NerdFont) {
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    if (Get-ChildItem -Path $fontDir -Filter "$NerdFont*NerdFont*" -ErrorAction SilentlyContinue) {
        Write-Step "$NerdFont Nerd Font already installed"
    } else {
        Write-Step "Installing the $NerdFont Nerd Font for your user"
        $zip = Join-Path $env:TEMP "$NerdFont.zip"
        $unpacked = Join-Path $env:TEMP "$NerdFont-nerd-font"
        Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$NerdFont.zip" -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $unpacked -Force
        New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
        $fontsKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        Get-ChildItem -Path $unpacked -Include *.ttf, *.otf -Recurse | ForEach-Object {
            $target = Join-Path $fontDir $_.Name
            Copy-Item $_.FullName $target -Force
            New-ItemProperty -Path $fontsKey -Name "$($_.BaseName) (TrueType)" -Value $target -PropertyType String -Force | Out-Null
        }
        Remove-Item $zip, $unpacked -Recurse -Force
        Write-Host "    Pick '$NerdFont Nerd Font' in Windows Terminal: Settings > $Distro > Appearance > Font face."
    }
}

if ($SkipSetup) {
    Write-Step "Done (setup skipped). Next: wsl -d $Distro, then clone linux-land and run ./setup.sh"
    exit 0
}

# --- 5. linux-land ---------------------------------------------------------------------
Write-Step "Cloning linux-land and running setup.sh in $Distro"
Invoke-InDistro -Script @"
set -e
command -v git >/dev/null && command -v curl >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq git curl; }
dir=$RepoDir
dir="`${dir/#\~/`$HOME}"
if [ ! -d "`$dir/.git" ]; then
    mkdir -p "`$(dirname "`$dir")"
    git clone $RepoUrl "`$dir"
fi
cd "`$dir"
./setup.sh
"@

Write-Step "Done. In $Distro, to install what another machine has:"
Write-Host "    1. copy that machine's linux-land/machines/NAME/bundle/ folder into the same place here"
Write-Host "    2. machine diff NAME      # what is missing"
Write-Host "    3. machine restore NAME   # install it"

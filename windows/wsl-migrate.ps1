<#
.SYNOPSIS
Copies a whole WSL distro to another Windows machine: export it to a .tar here, import
it there. Everything inside comes along: files, packages, keys and credentials.

.DESCRIPTION
For a selective copy (packages and tools, but not your files and credentials) use
linux-land's `machine snapshot` / `machine restore` instead.

Export stops the distro first (wsl --terminate) so the archive is consistent, and
copies %USERPROFILE%\.wslconfig next to the .tar. Import registers the distro from
the .tar as WSL 2, sets the default user (an imported distro otherwise logs in as
root) and puts the .wslconfig in place if this machine has none.

.EXAMPLE
.\wsl-migrate.ps1 -Export D:\backups\ubuntu-24.04.tar -Distro Ubuntu-24.04

.EXAMPLE
.\wsl-migrate.ps1 -Import D:\backups\ubuntu-24.04.tar -Distro Ubuntu-24.04 -User jstevens
#>
[CmdletBinding(DefaultParameterSetName = "export")]
param(
    [Parameter(ParameterSetName = "export", Mandatory)][string]$Export,
    [Parameter(ParameterSetName = "import", Mandatory)][string]$Import,
    [string]$Distro = "Ubuntu-24.04",
    [Parameter(ParameterSetName = "import")][string]$InstallDir = "",
    [Parameter(ParameterSetName = "import", Mandatory)][string]$User
)

$ErrorActionPreference = "Stop"
$env:WSL_UTF8 = "1"
$wslConfig = Join-Path $env:USERPROFILE ".wslconfig"

if ($PSCmdlet.ParameterSetName -eq "export") {
    Write-Host "==> Stopping $Distro and exporting it to $Export (this takes a while)"
    & wsl.exe --terminate $Distro | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Export) | Out-Null
    & wsl.exe --export $Distro $Export
    if ($LASTEXITCODE -ne 0) { throw "wsl --export failed" }
    if (Test-Path $wslConfig) {
        Copy-Item $wslConfig (Join-Path (Split-Path -Parent $Export) "wslconfig")
        Write-Host "    copied .wslconfig next to it as 'wslconfig'"
    }
    Write-Host "==> Done. On the other machine: .\wsl-migrate.ps1 -Import $Export -Distro $Distro -User <linux user>"
    exit 0
}

if (-not $InstallDir) { $InstallDir = Join-Path $env:LOCALAPPDATA "WSL\$Distro" }
$installed = @(& wsl.exe --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($installed -contains $Distro) {
    throw "$Distro already exists here. Pick another -Distro name, or remove it first (wsl --unregister $Distro deletes it and its files)."
}
Write-Host "==> Importing $Import as $Distro into $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
& wsl.exe --import $Distro $InstallDir $Import --version 2
if ($LASTEXITCODE -ne 0) { throw "wsl --import failed" }

Write-Host "==> Making $User the default user"
& wsl.exe -d $Distro -u root -- id $User *> $null
if ($LASTEXITCODE -ne 0) { throw "the imported distro has no user '$User'" }
$script = "grep -q '^\[user\]' /etc/wsl.conf 2>/dev/null && sed -i '/^\[user\]/,/^\[/{s/^default *=.*/default=$User/}' /etc/wsl.conf || printf '\n[user]\ndefault=$User\n' >> /etc/wsl.conf"
& wsl.exe -d $Distro -u root -- sh -c $script

$exported = Join-Path (Split-Path -Parent $Import) "wslconfig"
if ((Test-Path $exported) -and -not (Test-Path $wslConfig)) {
    Copy-Item $exported $wslConfig
    Write-Host "    installed the exported .wslconfig"
}
& wsl.exe --terminate $Distro | Out-Null
Write-Host "==> Done. Start it with: wsl -d $Distro"

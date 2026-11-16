#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Cs2Cfg = "",
    [switch]$RemoveUserConfig,
    [switch]$NoBackup,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Resolve-CfgDirectory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path is empty."
    }

    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw "Not a directory: $resolved"
    }

    $candidates = @(
        $resolved,
        (Join-Path $resolved "game\csgo\cfg"),
        (Join-Path $resolved "csgo\cfg"),
        (Join-Path $resolved "cfg")
    )

    foreach ($candidate in $candidates) {
        if ((Test-Path -LiteralPath $candidate -PathType Container) -and
            ((Split-Path -Leaf $candidate) -ieq "cfg")) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Could not find a csgo cfg directory under: $resolved"
}

function Get-SteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]

    $registryEntries = @(
        @{ Path = "HKCU:\Software\Valve\Steam"; Name = "SteamPath" },
        @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"; Name = "InstallPath" },
        @{ Path = "HKLM:\SOFTWARE\Valve\Steam"; Name = "InstallPath" }
    )

    foreach ($entry in $registryEntries) {
        try {
            $props = Get-ItemProperty -Path $entry.Path -ErrorAction Stop
            $value = $props.($entry.Name)
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $roots.Add($value)
            }
        } catch {
            # Missing registry entries are expected on some systems.
        }
    }

    $programFilesX86 = ${env:ProgramFiles(x86)}
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $roots.Add((Join-Path $programFilesX86 "Steam"))
    }

    $programFiles = ${env:ProgramFiles}
    if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
        $roots.Add((Join-Path $programFiles "Steam"))
    }

    return $roots |
        Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } |
        Select-Object -Unique
}

function Get-SteamLibraries {
    param([string]$SteamRoot)

    $libraries = New-Object System.Collections.Generic.List[string]
    $libraries.Add($SteamRoot)

    $vdfFiles = @(
        (Join-Path $SteamRoot "steamapps\libraryfolders.vdf"),
        (Join-Path $SteamRoot "config\libraryfolders.vdf")
    )

    foreach ($vdf in $vdfFiles) {
        if (-not (Test-Path -LiteralPath $vdf -PathType Leaf)) {
            continue
        }

        $content = Get-Content -LiteralPath $vdf -Raw
        foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
            $libraryPath = $match.Groups[1].Value.Replace('\\', '\')
            if (-not [string]::IsNullOrWhiteSpace($libraryPath)) {
                $libraries.Add($libraryPath)
            }
        }
    }

    return $libraries |
        Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } |
        Select-Object -Unique
}

function Find-Cs2CfgDirectory {
    $steamRoots = @(Get-SteamRoots)

    foreach ($steamRoot in $steamRoots) {
        $libraries = @(Get-SteamLibraries -SteamRoot $steamRoot)
        foreach ($library in $libraries) {
            foreach ($folderName in @("Counter-Strike Global Offensive", "Counter-Strike 2")) {
                $candidate = Join-Path $library "steamapps\common\$folderName\game\csgo\cfg"
                if (Test-Path -LiteralPath $candidate -PathType Container) {
                    return (Resolve-Path -LiteralPath $candidate).Path
                }
            }
        }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($Cs2Cfg)) {
    $cfgDir = Find-Cs2CfgDirectory
    if (-not $cfgDir) {
        throw "Could not locate CS2. Use -Cs2Cfg `"D:\path\to\game\csgo\cfg`"."
    }
} else {
    $cfgDir = Resolve-CfgDirectory -Path $Cs2Cfg
}

$managedFiles = @(
    "nade.cfg",
    "nade_common.cfg",
    "nade_binds.cfg",
    "nade_user.cfg",
    "nade_help.cfg",
    "nade_off.cfg",
    "nade_ancient.cfg",
    "nade_anubis.cfg",
    "nade_cache.cfg",
    "nade_dust2.cfg",
    "nade_inferno.cfg",
    "nade_mirage.cfg",
    "nade_nuke.cfg"
)

Write-Host ""
Write-Host "CS2 Nade Training uninstaller"
Write-Host "Target: $cfgDir"
Write-Host "Run 'exec nade_off' in CS2 before uninstalling to clear the binds."
Write-Host ""

$existing = @()
foreach ($name in $managedFiles) {
    $path = Join-Path $cfgDir $name
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        if ($name -ieq "nade_user.cfg" -and -not $RemoveUserConfig) {
            Write-Host "Preserving: $name (use -RemoveUserConfig to remove it)"
            continue
        }
        $existing += Get-Item -LiteralPath $path
    }
}

if ($existing.Count -eq 0) {
    Write-Host "No managed files found."
    exit 0
}

if (-not $NoBackup) {
    $backupDir = Join-Path $cfgDir ("nade_backup_" + (Get-Date -Format "yyyyMMdd-HHmmss") + "_" + $PID)
    if ($DryRun) {
        Write-Host "Would back up files to: $backupDir"
    } else {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        foreach ($file in $existing) {
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $backupDir $file.Name) -Force
        }
        Write-Host "Backed up files to: $backupDir"
    }
}

foreach ($file in $existing) {
    if ($DryRun) {
        Write-Host "Would remove: $($file.Name)"
    } else {
        Remove-Item -LiteralPath $file.FullName -Force
        Write-Host "Removed: $($file.Name)"
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete. No files were changed."
} else {
    Write-Host "Uninstall complete."
}

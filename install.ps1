#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Cs2Cfg = "",
    [switch]$Force,
    [switch]$NoBackup,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Join-Path $scriptRoot "cfg"

if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) {
    throw "Config folder not found: $sourceDir"
}

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

function New-ConfigBackup {
    param([string]$TargetDir)

    $existing = @(Get-ChildItem -LiteralPath $TargetDir -Filter "nade_*.cfg" -File -ErrorAction SilentlyContinue)
    if ($existing.Count -eq 0) {
        return $null
    }

    $backupDir = Join-Path $TargetDir ("nade_backup_" + (Get-Date -Format "yyyyMMdd-HHmmss") + "_" + $PID)
    if ($DryRun) {
        return $backupDir
    }

    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($file in $existing) {
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $backupDir $file.Name) -Force
    }

    return $backupDir
}

if ([string]::IsNullOrWhiteSpace($Cs2Cfg)) {
    $cfgDir = Find-Cs2CfgDirectory
    if (-not $cfgDir) {
        throw "Could not locate CS2. Use -Cs2Cfg `"D:\path\to\game\csgo\cfg`"."
    }
} else {
    $cfgDir = Resolve-CfgDirectory -Path $Cs2Cfg
}

$sourceFiles = @(Get-ChildItem -LiteralPath $sourceDir -Filter "*.cfg" -File | Sort-Object Name)
if ($sourceFiles.Count -eq 0) {
    throw "No .cfg files found in: $sourceDir"
}

Write-Host ""
Write-Host "CS2 Nade Training installer"
Write-Host "Source: $sourceDir"
Write-Host "Target: $cfgDir"

$backupDir = $null
if (-not $NoBackup) {
    $backupDir = New-ConfigBackup -TargetDir $cfgDir
    if ($backupDir) {
        if ($DryRun) {
            Write-Host "Would back up existing configs to: $backupDir"
        } else {
            Write-Host "Backed up existing configs to: $backupDir"
        }
    }
}

$preserveUser = (-not $Force) -and (Test-Path -LiteralPath (Join-Path $cfgDir "nade_user.cfg") -PathType Leaf)
$copied = 0

foreach ($file in $sourceFiles) {
    if ($preserveUser -and $file.Name -ieq "nade_user.cfg") {
        Write-Host "Preserving existing nade_user.cfg (use -Force to overwrite)"
        continue
    }

    $destination = Join-Path $cfgDir $file.Name
    if ($DryRun) {
        Write-Host "Would install: $($file.Name)"
    } else {
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        Write-Host "Installed: $($file.Name)"
    }
    $copied++
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete. No files were changed."
} else {
    Write-Host "Installed $copied file(s) to: $cfgDir"
}
Write-Host ""
Write-Host "Next:"
Write-Host "  1. Start CS2 and load a practice map."
Write-Host "  2. Open the console and run: exec nade_mirage"
Write-Host "  3. Run exec nade_help for the full command list."

# Enumerate all available (ready) drives instead of a static C:\
$searchPaths = [System.IO.DriveInfo]::GetDrives() |
    Where-Object { $_.IsReady } |
    ForEach-Object { $_.RootDirectory.FullName }

$keyword = "<FILE_NAME_GOES_HERE>"

$results = [System.Collections.Generic.List[string]]::new()

Write-Output "`nStarting search at $(Get-Date)"
Write-Output "Keyword: '$keyword'"
Write-Output "Drives : $($searchPaths -join ', ')"
Write-Output ("=" * 60)

# ─────────────────────────────────────────────
# 1. FILE SYSTEM SEARCH
# ─────────────────────────────────────────────
Write-Output "`n[*] Scanning file system..."

$fsMatches = [System.Collections.Generic.List[string]]::new()

foreach ($searchPath in $searchPaths) {
    Write-Output "    -> Scanning $searchPath"
    Get-ChildItem -Path $searchPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -like "*$keyword*") {
            $fsMatches.Add($_.FullName)
        }
    }
}

if ($fsMatches.Count -gt 0) {
    $results.Add("`n[FILE SYSTEM MATCHES]")
    foreach ($match in $fsMatches) {
        $results.Add("  Found: $match")
    }
} else {
    $results.Add("`n[FILE SYSTEM MATCHES]`n  No matches found.")
}

# ─────────────────────────────────────────────
# 2. RUNNING PROCESSES
# ─────────────────────────────────────────────
Write-Output "[*] Scanning running processes..."

$procMatches = [System.Collections.Generic.List[string]]::new()

Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*$keyword*" -or $_.Path -like "*$keyword*"
} | ForEach-Object {
    $procMatches.Add("  PID: $($_.Id) | Name: $($_.Name) | Path: $($_.Path)")
}

if ($procMatches.Count -gt 0) {
    $results.Add("`n[RUNNING PROCESS MATCHES]")
    $results.AddRange($procMatches)
} else {
    $results.Add("`n[RUNNING PROCESS MATCHES]`n  No matches found.")
}

# ─────────────────────────────────────────────
# 3. SCHEDULED TASKS
# ─────────────────────────────────────────────
Write-Output "[*] Scanning scheduled tasks..."

$taskMatches = [System.Collections.Generic.List[string]]::new()

Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -like "*$keyword*" -or
    $_.TaskPath -like "*$keyword*" -or
    ($_.Actions | Where-Object { $_.Execute -like "*$keyword*" -or $_.Arguments -like "*$keyword*" })
} | ForEach-Object {
    $action = ($_.Actions | Select-Object -First 1)
    $taskMatches.Add("  Task: $($_.TaskPath)$($_.TaskName) | Execute: $($action.Execute) $($action.Arguments) | State: $($_.State)")
}

if ($taskMatches.Count -gt 0) {
    $results.Add("`n[SCHEDULED TASK MATCHES]")
    $results.AddRange($taskMatches)
} else {
    $results.Add("`n[SCHEDULED TASK MATCHES]`n  No matches found.")
}

# ─────────────────────────────────────────────
# 4. REGISTRY PERSISTENCE CHECKS
# ─────────────────────────────────────────────
Write-Output "[*] Scanning registry for persistence..."

$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
)

$regMatches = [System.Collections.Generic.List[string]]::new()

foreach ($regPath in $registryPaths) {
    if (-not (Test-Path $regPath -ErrorAction SilentlyContinue)) { continue }

    if ($regPath -match "Run") {
        $key = Get-Item -Path $regPath -ErrorAction SilentlyContinue
        if ($key) {
            foreach ($valueName in $key.GetValueNames()) {
                $valueData = $key.GetValue($valueName)
                if ($valueName -like "*$keyword*" -or $valueData -like "*$keyword*") {
                    $regMatches.Add("  Path: $regPath")
                    $regMatches.Add("    Value Name : $valueName")
                    $regMatches.Add("    Value Data : $valueData")
                }
            }
        }
    } else {
        Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue | ForEach-Object {
            $displayName     = $_.GetValue("DisplayName")
            $installLocation = $_.GetValue("InstallLocation")
            $uninstallString = $_.GetValue("UninstallString")

            if (
                $_.PSChildName   -like "*$keyword*" -or
                $displayName     -like "*$keyword*" -or
                $installLocation -like "*$keyword*" -or
                $uninstallString -like "*$keyword*"
            ) {
                $regMatches.Add("  Path: $($_.PSPath)")
                $regMatches.Add("    DisplayName     : $displayName")
                $regMatches.Add("    InstallLocation : $installLocation")
                $regMatches.Add("    UninstallString : $uninstallString")
            }
        }
    }
}

if ($regMatches.Count -gt 0) {
    $results.Add("`n[REGISTRY PERSISTENCE MATCHES]")
    $results.AddRange($regMatches)
} else {
    $results.Add("`n[REGISTRY PERSISTENCE MATCHES]`n  No matches found.")
}

# ─────────────────────────────────────────────
# FINAL OUTPUT
# ─────────────────────────────────────────────
Write-Output ("`n" + ("=" * 60))
Write-Output "SEARCH RESULTS FOR: '$keyword'"
Write-Output ("=" * 60)

$results | ForEach-Object { Write-Output $_ }

Write-Output ("`n" + ("=" * 60))
Write-Output "Search completed at $(Get-Date)"

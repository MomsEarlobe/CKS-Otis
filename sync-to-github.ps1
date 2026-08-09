<#
.SYNOPSIS
    Watches the CKS-Otis repo folder for file changes and auto-pushes to GitHub.

.DESCRIPTION
    Uses FileSystemWatcher to detect new, changed, renamed, or deleted files
    in the repo directory. When changes are detected, it waits a few seconds
    for batch changes to settle, then stages, commits, and pushes to GitHub.

.USAGE
    .\sync-to-github.ps1
    
    Press Ctrl+C to stop watching.
#>

$repoPath = $PSScriptRoot
Set-Location $repoPath

# Colors for output
function Write-Status($msg) { Write-Host "[SYNC] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERR]  $msg" -ForegroundColor Red }

# Verify we're in a git repo
if (-not (Test-Path "$repoPath\.git")) {
    Write-Err "Not a git repository. Run this script from inside the CKS-Otis repo folder."
    exit 1
}

Write-Status "Watching for changes in: $repoPath"
Write-Status "Press Ctrl+C to stop."
Write-Host ""

# Create the FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repoPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $false
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor
                         [System.IO.NotifyFilters]::DirectoryName -bor
                         [System.IO.NotifyFilters]::LastWrite -bor
                         [System.IO.NotifyFilters]::Size

# Debounce: collect changes, then push after a quiet period
$debounceSeconds = 5
$lastChangeTime = [datetime]::MinValue
$pendingChanges = @()

function Push-Changes {
    param([string[]]$changes)
    
    # Check if there are actual git changes
    $status = git status --porcelain 2>&1
    if (-not $status) {
        Write-Warn "No actual git changes detected (might be .gitignored files). Skipping."
        return
    }

    $changeCount = ($status | Measure-Object).Count
    Write-Status "Staging $changeCount file(s)..."

    git add -A 2>&1 | Out-Null

    # Build commit message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $commitMsg = "Auto-sync: $changeCount file(s) changed @ $timestamp"
    
    Write-Status "Committing: $commitMsg"
    $commitResult = git commit -m $commitMsg 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Commit failed: $commitResult"
        return
    }

    Write-Status "Pushing to GitHub..."
    $pushResult = git push origin main 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        # Try pushing to master if main doesn't exist
        $pushResult = git push origin master 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Push failed: $pushResult"
            return
        }
    }

    Write-Success "Pushed $changeCount change(s) to GitHub!"
    Write-Host ""
}

# Main watch loop
$watcher.EnableRaisingEvents = $true

try {
    while ($true) {
        $result = $watcher.WaitForChanged(
            [System.IO.WatcherChangeTypes]::All, 
            1000  # Check every 1 second
        )
        
        if (-not $result.TimedOut) {
            $changedFile = $result.Name
            
            # Skip .git directory changes and desktop.ini
            if ($changedFile -like ".git*" -or $changedFile -like "*desktop.ini") {
                continue
            }

            $lastChangeTime = Get-Date
            $pendingChanges += $changedFile
            Write-Status "Change detected: $changedFile ($($result.ChangeType))"
        }
        
        # If we have pending changes and enough quiet time has passed, push
        if ($pendingChanges.Count -gt 0) {
            $elapsed = (Get-Date) - $lastChangeTime
            if ($elapsed.TotalSeconds -ge $debounceSeconds) {
                Write-Host ""
                Write-Status "Quiet period reached. Syncing $($pendingChanges.Count) change(s)..."
                Push-Changes -changes $pendingChanges
                $pendingChanges = @()
            }
        }
    }
}
finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Write-Status "Watcher stopped."
}

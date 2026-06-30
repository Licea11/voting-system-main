param(
  [Parameter(Position = 0)]
  [ValidateSet('status', 'fetch', 'pull', 'push', 'merge', 'sync', 'remote')]
  [string]$Action = 'status',
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
  throw 'Use the Bash helper from WSL/Linux for this repo.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repoRoot '.git'))) {
  throw 'Run this script from the repository or keep it under repo/scripts.'
}

Set-Location $repoRoot
switch ($Action) {
  'status' {
    git status --short --branch
    git remote -v
  }
  'remote' {
    git remote -v
  }
  'fetch' {
    if ($Args.Count -gt 0) {
      git fetch @Args
    } else {
      git fetch origin
    }
  }
  'pull' {
    if ($Args.Count -gt 0) {
      git pull @Args
    } else {
      $branch = (git branch --show-current).Trim()
      if ($branch) {
        git pull origin $branch
      } else {
        git pull origin
      }
    }
  }
  'push' {
    if ($Args.Count -gt 0) {
      git push @Args
    } else {
      $branch = (git branch --show-current).Trim()
      if ($branch) {
        git push origin $branch
      } else {
        git push origin
      }
    }
  }
  'merge' {
    if ($Args.Count -eq 0) {
      throw 'merge requires a branch name.'
    }
    git merge @Args
  }
  'sync' {
    $branch = (git branch --show-current).Trim()
    if (-not $branch) {
      throw 'sync requires a checked-out branch.'
    }
    git fetch origin
    git pull --ff-only origin $branch
  }
}

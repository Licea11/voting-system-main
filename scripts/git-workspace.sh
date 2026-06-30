#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${WSL_DISTRO_NAME:-}" && "$(uname -s)" == MINGW* ]]; then
  echo "Use the PowerShell helper on Windows for this repo." >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -d "$repo_root/.git" ]]; then
  echo "Run this script from the repository or keep it under repo/scripts." >&2
  exit 1
fi

cd "$repo_root"
action="${1:-status}"
shift || true

case "$action" in
  status)
    git status --short --branch
    git remote -v
    ;;
  remote)
    git remote -v
    ;;
  fetch)
    if [[ $# -gt 0 ]]; then
      git fetch "$@"
    else
      git fetch origin
    fi
    ;;
  pull)
    if [[ $# -gt 0 ]]; then
      git pull "$@"
    else
      branch="$(git branch --show-current)"
      if [[ -n "$branch" ]]; then
        git pull origin "$branch"
      else
        git pull origin
      fi
    fi
    ;;
  push)
    if [[ $# -gt 0 ]]; then
      git push "$@"
    else
      branch="$(git branch --show-current)"
      if [[ -n "$branch" ]]; then
        git push origin "$branch"
      else
        git push origin
      fi
    fi
    ;;
  merge)
    if [[ $# -eq 0 ]]; then
      echo "merge requires a branch name." >&2
      exit 1
    fi
    git merge "$@"
    ;;
  sync)
    branch="$(git branch --show-current)"
    if [[ -z "$branch" ]]; then
      echo "sync requires a checked-out branch." >&2
      exit 1
    fi
    git fetch origin
    git pull --ff-only origin "$branch"
    ;;
  *)
    echo "usage: git-workspace.sh [status|remote|fetch|pull|push|merge|sync]" >&2
    exit 1
    ;;
esac

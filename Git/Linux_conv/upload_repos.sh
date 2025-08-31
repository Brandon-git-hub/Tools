#!/usr/bin/env bash
set -Eeuo pipefail

# GitHub username/org
ORG="Brandon-git-hub"

# Project list (relative to current working directory)
REPOS=(
  "NAFNet"
  "MIMO-UNet"
  "HIDiff"
  "IQA/CLIP_IQA"
  "IQA/MANIQA"
  "IQA/musiq"
)

# Ensure required commands exist
for cmd in git gh; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd"; exit 1; }
done

for d in "${REPOS[@]}"; do
  if [[ -d "$d/.git" ]]; then
    repo_dir="$d"
    repo_name="$(basename "$d")_mine"
    echo "=== Processing $repo_name ==="

    (
      set -Eeuo pipefail
      cd "$repo_dir"

      # 1) Stage and commit local changes if any (message = today in YYYY/MM/DD)
      # Stage everything (modified + untracked)
      git add -A

      # Commit only if there is something staged
      if ! git diff --cached --quiet; then
        commit_msg="$(date +%Y/%m/%d)"
        git commit -m "$commit_msg"
        echo "Committed local changes with message: $commit_msg"
      else
        echo "No local changes to commit"
      fi

      # 2) Remove old origin if exists
      git remote remove origin 2>/dev/null || true

      # 3) Create GitHub repo (private). If exists, skip creation.
      if gh repo create "$ORG/$repo_name" --private --disable-wiki --enable-issues=false; then
        echo "Created GitHub repo: $ORG/$repo_name"
      else
        echo "Repo $ORG/$repo_name may already exist. Continuing."
      fi

      # 4) Set HTTPS remote (you will be prompted for PAT on first push)
      git remote add origin "https://github.com/$ORG/$repo_name.git" 2>/dev/null || true

      # 5) Determine default branch
      # Try current HEAD; fallback to main or master if needed
      default_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
      if [[ -z "${default_branch:-}" ]]; then
        if git rev-parse --verify main >/dev/null 2>&1; then
          default_branch="main"
          git checkout main
        elif git rev-parse --verify master >/dev/null 2>&1; then
          default_branch="master"
          git checkout master
        else
          # If no branch, create main
          default_branch="main"
          git checkout -b main
          git commit --allow-empty -m "Initialize default branch"
        fi
      fi

      # 6) Push all branches and tags
      git push -u origin --all
      git push origin --tags

      # 7) Set default branch on GitHub (best-effort)
      gh repo edit "$ORG/$repo_name" --default-branch "$default_branch" >/dev/null 2>&1 || true

      echo "Done: $repo_name"
    )
  else
    echo "Skipping $d (not a git repo directory)"
  fi
done

echo "All done."
echo "If prompted for credentials:"
echo "  Username: your GitHub username"
echo "  Password: your Personal Access Token (PAT)"

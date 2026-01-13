#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GitHub Actions Cleanup Script
# Usage: ./scripts/cleanup-workflows.sh [--dry-run]
# =============================================================================

REPO="${GITHUB_REPOSITORY:-cakmoel/resilio}"
DRY_RUN=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="--dry-run"
      shift
      ;;
    *)
      echo "Usage: $0 [--dry-run]"
      exit 1
      ;;
  esac
done

# Check for gh CLI
if ! command -v gh >/dev/null; then
  echo "❌ GitHub CLI (gh) not installed"
  echo "Install: https://cli.github.com/manual/installation"
  exit 1
fi

echo "=== GitHub Actions Cleanup for $REPO ==="
echo ""

# Get all workflow runs
echo "📊 Fetching workflow runs..."
runs=$(gh run list --repo "$REPO" --limit 50 --json id,conclusion,created_at,displayTitle,headBranch)

if [[ -z "$runs" ]]; then
  echo "✅ No workflow runs found"
  exit 0
fi

# Parse and filter runs
echo "🔍 Analyzing runs..."
count=0
deleted=0

while IFS= read -r run; do
  if [[ -z "$run" ]]; then continue; fi
  
  id=$(echo "$run" | jq -r '.id')
  conclusion=$(echo "$run" | jq -r '.conclusion')
  created_at=$(echo "$run" | jq -r '.created_at')
  title=$(echo "$run" | jq -r '.displayTitle')
  branch=$(echo "$run" | jq -r '.headBranch')
  
  ((count++))
  
  # Delete criteria
  should_delete=false
  reason=""
  
  # Delete failed runs older than 7 days
  if [[ "$conclusion" == "failure" ]]; then
    run_date=$(date -d "$created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s)
    cutoff=$(date -d "7 days ago" +%s 2>/dev/null || date -v-7d +%s)
    
    if [[ $run_date -lt $cutoff ]]; then
      should_delete=true
      reason="Failed run older than 7 days"
    fi
  fi
  
  # Delete successful runs older than 30 days (keep last 10)
  if [[ "$conclusion" == "success" ]]; then
    run_date=$(date -d "$created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s)
    cutoff=$(date -d "30 days ago" +%s 2>/dev/null || date -v-30d +%s)
    
    if [[ $run_date -lt $cutoff && $count -gt 10 ]]; then
      should_delete=true
      reason="Old successful run (not in last 10)"
    fi
  fi
  
  # Skip main branch runs (keep for reference)
  if [[ "$branch" == "main" ]]; then
    should_delete=false
  fi
  
  if [[ "$should_delete" == "true" ]]; then
    echo "🗑️  $title (ID: $id) - $reason"
    if [[ -z "$DRY_RUN" ]]; then
      if gh run delete "$id" --repo "$REPO" >/dev/null 2>&1; then
        echo "   ✅ Deleted"
        ((deleted++))
      else
        echo "   ❌ Failed to delete"
      fi
    else
      echo "   📋 Would delete (dry run)"
      ((deleted++))
    fi
  else
    echo "✅ Keeping $title (ID: $id)"
  fi
  
done <<< "$runs"

echo ""
echo "📈 Summary:"
echo "   Total runs analyzed: $count"
echo "   Runs to delete: $deleted"
echo "   Mode: ${DRY_RUN:-Live deletion}"

if [[ -n "$DRY_RUN" ]]; then
  echo ""
  echo "💡 To actually delete, run without --dry-run"
else
  echo ""
  echo "🎉 Cleanup completed!"
fi
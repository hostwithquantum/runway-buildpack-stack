#!/bin/bash
set -euo pipefail

# Usage: ./scripts/generate-changelog.sh [from-tag] [to-ref]
# Example: ./scripts/generate-changelog.sh v0.15.0 HEAD
# Example: ./scripts/generate-changelog.sh v0.15.0 v0.16.0

FROM_TAG="${1:-$(git describe --tags --abbrev=0)}"
TO_REF="${2:-HEAD}"

echo "# Buildpack Changelog"
echo "**From:** $FROM_TAG ($(git log -1 --format=%ai "$FROM_TAG" | cut -d' ' -f1))"
echo "**To:** $TO_REF ($(date +%Y-%m-%d))"
echo ""
echo "---"
echo ""

for buildpack in dotnet-core go java java-native-image nodejs php python ruby runway; do
  diff=$(git diff "$FROM_TAG..$TO_REF" "meta/$buildpack/buildpack.toml" 2>/dev/null || true)

  if [ -z "$diff" ]; then
    continue
  fi

  old_version=$(git show "$FROM_TAG:meta/$buildpack/buildpack.toml" 2>/dev/null | grep "^  version = " | head -1 | cut -d'"' -f2 || echo "unknown")
  new_version=$(git show "$TO_REF:meta/$buildpack/buildpack.toml" 2>/dev/null | grep "^  version = " | head -1 | cut -d'"' -f2 || echo "unknown")

  echo "## $buildpack"
  echo "**Buildpack:** $old_version → **$new_version**"
  echo ""
  echo "### Dependency Updates"

  # Parse dependency updates
  git diff "$FROM_TAG..$TO_REF" "meta/$buildpack/buildpack.toml" 2>/dev/null | \
    grep -E "^\+.*version = |^\-.*version = " | \
    while IFS= read -r line; do
      if [[ $line =~ version\ =\ \"([^\"]+)\" ]]; then
        version="${BASH_REMATCH[1]}"
        if [[ $line == -* ]]; then
          echo "OLD::$version"
        else
          echo "NEW::$version"
        fi
      fi
    done | \
    paste -d' ' - - | \
    while read -r old_line new_line; do
      old_ver="${old_line#OLD::}"
      new_ver="${new_line#NEW::}"

      # Get dependency ID from the context
      dep_id=$(git diff "$FROM_TAG..$TO_REF" "meta/$buildpack/buildpack.toml" 2>/dev/null | \
        grep -B2 "version = \"$old_ver\"" | \
        grep "id = " | \
        head -1 | \
        cut -d'"' -f2 || echo "unknown")

      if [ "$dep_id" != "unknown" ] && [ "$old_ver" != "$new_ver" ]; then
        # Check for major version changes
        old_major=$(echo "$old_ver" | cut -d. -f1)
        new_major=$(echo "$new_ver" | cut -d. -f1)

        if [ "$old_major" != "$new_major" ]; then
          echo "- **$dep_id** → $old_ver to $new_ver ⚠️ MAJOR"
        else
          echo "- $dep_id → $old_ver to $new_ver"
        fi
      fi
    done | sort -u

  echo ""
  echo "---"
  echo ""
done

echo "## Summary"
echo ""
total_updated=$(git diff "$FROM_TAG..$TO_REF" -- 'meta/*/buildpack.toml' 2>/dev/null | grep -c "^diff --git" || echo 0)
echo "**Total Buildpack Updates:** $total_updated"
echo ""

# Count major updates by looking for ⚠️ MAJOR markers in the output
major_count=$(git diff "$FROM_TAG..$TO_REF" -- 'meta/*/buildpack.toml' 2>/dev/null | \
  grep -E "^\+.*version = |^\-.*version = " | \
  grep -v "^  version = " | \
  while IFS= read -r line; do
    if [[ $line =~ version\ =\ \"([^\"]+)\" ]]; then
      version="${BASH_REMATCH[1]}"
      major="${version%%.*}"
      if [[ $line == -* ]]; then
        echo "OLD::$major"
      else
        echo "NEW::$major"
      fi
    fi
  done | \
  paste -d' ' - - 2>/dev/null | \
  awk '{if ($1 != $2) count++} END {print count+0}')

if [ "${major_count:-0}" -gt 0 ]; then
  echo "**Major Version Updates:** $major_count dependencies with major version bumps"
else
  echo "**Major Version Updates:** None"
fi

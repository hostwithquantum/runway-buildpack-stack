#!/bin/bash
set -euo pipefail

# Usage: ./scripts/generate-changelog.sh [from-tag] [to-ref]
# Example: ./scripts/generate-changelog.sh v0.15.0 HEAD
# Example: ./scripts/generate-changelog.sh v0.15.0 v0.16.0

FROM_TAG="${1:-$(git describe --tags --abbrev=0)}"
TO_REF="${2:-HEAD}"

# Extract unique dependency id=version pairs from [[order.group]] sections
extract_deps() {
  local ref=$1 buildpack=$2
  git show "$ref:meta/$buildpack/buildpack.toml" 2>/dev/null | awk -F'"' '
    /^\[buildpack\]/ { section="buildpack" }
    /^\[\[order\]\]/ { section="order" }
    /\[\[order\.group\]\]/ { section="group"; id="" }
    section == "group" && /id = / { id=$2 }
    section == "group" && /version = / { if (id != "") print id "=" $2; id="" }
  ' | sort -u -t= -k1,1
}

# Extract buildpack's own version from the [buildpack] section
extract_buildpack_version() {
  local ref=$1 buildpack=$2
  git show "$ref:meta/$buildpack/buildpack.toml" 2>/dev/null | awk -F'"' '
    /^\[buildpack\]/ { bp=1 }
    bp && /version = / { print $2; exit }
  '
}

echo "# Buildpack Changelog"
echo "**From:** $FROM_TAG ($(git log -1 --format=%ai "$FROM_TAG" | cut -d' ' -f1))"
echo "**To:** $TO_REF ($(date +%Y-%m-%d))"
echo ""
echo "---"
echo ""

total_updated=0
major_count=0

for buildpack in dotnet-core go java java-native-image nodejs php python ruby runway; do
  if git diff --quiet "$FROM_TAG..$TO_REF" -- "meta/$buildpack/buildpack.toml" 2>/dev/null; then
    continue
  fi

  old_version=$(extract_buildpack_version "$FROM_TAG" "$buildpack")
  new_version=$(extract_buildpack_version "$TO_REF" "$buildpack")
  total_updated=$((total_updated + 1))

  echo "## $buildpack"
  echo "**Buildpack:** ${old_version:-unknown} → **${new_version:-unknown}**"
  echo ""
  echo "### Dependency Updates"

  old_deps=$(extract_deps "$FROM_TAG" "$buildpack")
  new_deps=$(extract_deps "$TO_REF" "$buildpack")

  if [ -n "$old_deps" ] && [ -n "$new_deps" ]; then
    while IFS='=' read -r id old_ver new_ver; do
      if [ "$old_ver" != "$new_ver" ]; then
        old_major="${old_ver%%.*}"
        new_major="${new_ver%%.*}"

        if [ "$old_major" != "$new_major" ]; then
          echo "- **$id** → $old_ver to $new_ver ⚠️ MAJOR"
          major_count=$((major_count + 1))
        else
          echo "- $id → $old_ver to $new_ver"
        fi
      fi
    done < <(join -t= <(echo "$old_deps") <(echo "$new_deps"))
  fi

  echo ""
  echo "---"
  echo ""
done

echo "## Summary"
echo ""
echo "**Total Buildpack Updates:** $total_updated"
echo ""

if [ "$major_count" -gt 0 ]; then
  echo "**Major Version Updates:** $major_count dependencies with major version bumps"
else
  echo "**Major Version Updates:** None"
fi

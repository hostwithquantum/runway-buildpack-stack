#!/bin/bash

resp=$(gh api \
-H "Accept: application/vnd.github+json" \
-H "X-GitHub-Api-Version: 2022-11-28" \
/repos/paketo-community/go-generate/releases/latest)

version=$(echo $resp|jq -r .tag_name)
url=$(echo $resp|jq -r .assets[0].browser_download_url)

echo "version=${version:1}" >> $GITHUB_OUTPUT
echo "download_url=${url}" >> $GITHUB_OUTPUT

echo "### Debug" >> $GITHUB_STEP_SUMMARY
echo "- version: ${version}" >> $GITHUB_STEP_SUMMARY
echo "- url: ${url}" >> $GITHUB_STEP_SUMMARY
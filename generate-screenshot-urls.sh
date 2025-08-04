#!/bin/bash

# --- CONFIGURATION ---
GITHUB_USER="robinsr"
REPO_NAME="hyper-tag-browser"
BRANCH="main"
FOLDER="screenshots"
THUMB_FOLDER="thumbs"  # Subfolder within FOLDER

# --- SCRIPT ---
echo "📸 GitHub Raw URLs for Full-size and Thumbnail Images"
echo

for file in "$FOLDER"/*.png; do
  filename=$(basename "$file")
  full_url="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/$BRANCH/$FOLDER/$filename"
  thumb_url="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/$BRANCH/$FOLDER/$THUMB_FOLDER/$filename"

  echo "🖼️  $filename"
  echo "   Full:  $full_url"
  echo "   Thumb: $thumb_url"
  echo
done
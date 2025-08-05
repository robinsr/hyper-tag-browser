#!/bin/bash

# Resize all PNGs in screenshots/ to 25% size and save them in screenshots/thumbs/

SCREENSHOT_DIR="../"
THUMBNAIL_DIR="../thumbs"

mkdir -p $THUMBNAIL_DIR

for file in ../*.png; do
  filename=$(basename "$file")

  echo "📸 Resizing $filename to 25%"

  convert "$file" -resize 25% "$THUMBNAIL_DIR/$filename"
done
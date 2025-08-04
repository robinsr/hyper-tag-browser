#!/bin/bash

# Resize all PNGs in screenshots/ to 25% size and save them in screenshots/thumbs/

mkdir -p screenshots/thumbs

for file in screenshots/*.png; do
  filename=$(basename "$file")
  convert "$file" -resize 25% "screenshots/thumbs/$filename"
done
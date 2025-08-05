#!/bin/bash

# Screenshot directory
SCREENSHOT_DIR="../"

# Thumbnail directory
THUMBS_DIR="$SCREENSHOT_DIR/thumbs"

# Input filenames
LIGHT_IMAGE="$SCREENSHOT_DIR/040-hypertagbrowser-detail-main-light.png"
DARK_IMAGE="$SCREENSHOT_DIR/040-hypertagbrowser-detail-main-dark.png"

# Composite filename
FINAL_OUTPUT="$SCREENSHOT_DIR/040-hypertagbrowser-detail-main-diagonal.png"


# Output files
MASK="mask.png"
MASK_INVERTED="mask-inverted.png"
LIGHT_TRIANGLE="light-triangle.png"
DARK_TRIANGLE="dark-triangle.png"

# Get image dimensions
read WIDTH HEIGHT <<< $(identify -format "%w %h" "$LIGHT_IMAGE")

echo "🔍 Detected dimensions: ${WIDTH}x${HEIGHT}"

# 1. Create diagonal mask with transparent background and white top-left triangle
convert -size ${WIDTH}x${HEIGHT} canvas:none \
  -fill white -draw "polygon 0,0 0,${HEIGHT} ${WIDTH},0" \
  "$MASK"

# 2. Apply mask to light image as alpha channel
convert "$LIGHT_IMAGE" "$MASK" \
  -alpha on -compose CopyOpacity -composite \
  "$LIGHT_TRIANGLE"

# 3. Invert alpha of the mask (for dark image)
convert "$MASK" -channel A -negate +channel "$MASK_INVERTED"

# 4. Apply inverted mask to dark image
convert "$DARK_IMAGE" "$MASK_INVERTED" \
  -alpha on -compose CopyOpacity -composite \
  "$DARK_TRIANGLE"

# 5. Merge both triangles into final image with transparency
composite -compose over -background none "$DARK_TRIANGLE" "$LIGHT_TRIANGLE" "$FINAL_OUTPUT"

# 6. Clean up intermediate files
# rm "$MASK" "$MASK_INVERTED" "$LIGHT_TRIANGLE" "$DARK_TRIANGLE"


echo "✅ Composite saved to $FINAL_OUTPUT"
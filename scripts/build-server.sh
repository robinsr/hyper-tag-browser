#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_DIR="$REPO_ROOT/server"
OUTPUT="$BUILT_PRODUCTS_DIR/$WRAPPER_NAME/Contents/MacOS/HyperTagBrowserServer"

echo "Building Go server..."
echo "  Source: $SERVER_DIR"
echo "  Output: $OUTPUT"

mkdir -p "$(dirname "$OUTPUT")"

# Build a universal binary when both architectures are requested (e.g. Archive).
if echo "${ARCHS:-}" | grep -q "arm64" && echo "${ARCHS:-}" | grep -q "x86_64"; then
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    
    GOOS=darwin GOARCH=arm64 /opt/homebrew/bin/go -C "$SERVER_DIR" build \
      -o "$TMP/server-arm64" .
      
    GOOS=darwin GOARCH=amd64 /opt/homebrew/bin/go -C "$SERVER_DIR" build \
      -o "$TMP/server-amd64" .
      
    lipo -create \
      -output "$OUTPUT" \
      "$TMP/server-arm64" \
      "$TMP/server-amd64"

    echo "Built universal binary at $OUTPUT"
else
  # Single-architecture build.
  if echo "${ARCHS:-}" | grep -q "arm64"; then
      GOARCH="arm64"
  else
      GOARCH="amd64"
  fi

  GOOS=darwin GOARCH="$GOARCH" /opt/homebrew/bin/go -C "$SERVER_DIR" build \
    -o "$OUTPUT" .

  echo "Built $GOARCH binary at $OUTPUT"
fi

# Sign the nested executable before Xcode signs the enclosing app.
if [[ "${CODE_SIGNING_ALLOWED:-NO}" == "YES" ]]; then
    SIGNING_IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:--}"
    [[ -n "$SIGNING_IDENTITY" ]] || SIGNING_IDENTITY="-"

    /usr/bin/codesign \
        --force \
        --sign "$SIGNING_IDENTITY" \
        --options runtime \
        --timestamp=none \
        "$OUTPUT"
fi

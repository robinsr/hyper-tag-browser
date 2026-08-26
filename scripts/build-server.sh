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
    GOOS=darwin GOARCH=arm64 go build -o "$TMP/server-arm64" "$SERVER_DIR"
    GOOS=darwin GOARCH=amd64 go build -o "$TMP/server-amd64" "$SERVER_DIR"
    lipo -create -output "$OUTPUT" "$TMP/server-arm64" "$TMP/server-amd64"
    rm -rf "$TMP"
    echo "Built universal binary at $OUTPUT"
    exit 0
fi

# Single-architecture build.
if echo "${ARCHS:-}" | grep -q "arm64"; then
    GOARCH="arm64"
else
    GOARCH="amd64"
fi

cd $SERVER_DIR
GOOS=darwin GOARCH="$GOARCH" /opt/homebrew/bin/go build -o "$OUTPUT"
echo "Built $GOARCH binary at $OUTPUT"

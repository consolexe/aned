#!/usr/bin/env bash
URL="$1"
OUTBASE="$2"
if [[ -z "$URL" || -z "$OUTBASE" ]]; then
  echo "Usage: web_read.sh <url> <outbase>"
  exit 1
fi
apt-get update -y || true
apt-get install -y curl lynx || true
curl -s "$URL" -o "$OUTBASE.html"
lynx -dump "$OUTBASE.html" > "$OUTBASE.txt"
echo "$OUTBASE.txt"

#!/usr/bin/env bash
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
echo "[$(date)] $*" >> "$ROOT_DIR/core/memory.txt"
echo "OK"

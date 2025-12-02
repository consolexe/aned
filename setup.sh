#!/usr/bin/env bash
sudo apt update
sudo apt install -y jq curl lynx sqlite3 python3 python3-venv python3-pip
echo "Ensure 'ollama' CLI is installed separately and available in PATH."

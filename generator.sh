#!/usr/bin/env bash
MODEL="$1"
REQUEST="$2"
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
PROMPT_FILE="$ROOT/core/prompt.txt"
RAW="$ROOT/logs/raw_output.txt"
TASK="$ROOT/task.sh"

if [[ -z "$MODEL" || -z "$REQUEST" ]]; then
  echo "Usage: generator.sh <model> <request>"
  exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")
PROMPT="$PROMPT

USER_REQUEST: $REQUEST

### START\n<commands>\n### END"

ollama run "$MODEL" <<< "$PROMPT" > "$RAW" 2>&1 || true

sed -n '/### START/,/### END/p' "$RAW" | sed '1d;$d' > "$TASK"

if [[ ! -s "$TASK" ]]; then
  echo "[ERROR] Model did not produce commands. See $RAW"
  exit 1
fi

chmod +x "$TASK"
echo "[GENERATOR] Commands saved to $TASK"

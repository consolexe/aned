#!/usr/bin/env bash
LOG="$1"
TASK="$2"
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
FIXRAW="$ROOT/logs/fix_raw.txt"

if [[ -z "$LOG" || -z "$TASK" ]]; then
  echo "Usage: autofix.sh <log> <task>"
  exit 1
fi

ERR=$(tail -n 200 "$LOG")
CMDS=$(sed -n '1,500p' "$TASK" 2>/dev/null || true)

PROMPT="You are an AI DevOps assistant. The following commands failed. Provide corrected commands only between ### START and ### END.\nERROR:\n$ERR\nFAILED_CMDS:\n$CMDS\n### START\n<fixed_commands>\n### END"

ollama run qwen2.5:3b <<< "$PROMPT" > "$FIXRAW" 2>&1 || true
sed -n '/### START/,/### END/p' "$FIXRAW" | sed '1d;$d' > "$TASK"
chmod +x "$TASK"
echo "[AUTOFIX] Task rewritten; re-running executor..."
bash "$ROOT/core/executor.sh"

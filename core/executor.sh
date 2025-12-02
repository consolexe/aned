#!/usr/bin/env bash
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
TASK="$ROOT/task.sh"
LOGS="$ROOT/logs"
RESULT="$LOGS/result_$(date +%Y-%m-%d_%H-%M-%S).txt"

if [[ ! -f "$TASK" ]]; then
  echo "[EXECUTOR] No task to run ($TASK)"
  exit 1
fi

echo "[EXECUTOR] Running task... (log: $RESULT)"
bash "$TASK" > "$RESULT" 2>&1
RC=$?
echo "[EXECUTOR] Return code: $RC"

# append result to memory
echo "---" >> "$ROOT/core/memory.txt"
echo "$(date): RC=$RC" >> "$ROOT/core/memory.txt"
cat "$RESULT" >> "$ROOT/core/memory.txt"

if [[ $RC -ne 0 ]]; then
  echo "[EXECUTOR] Error detected, invoking autofix..."
  bash "$ROOT/core/autofix.sh" "$RESULT" "$TASK"
else
  echo "[EXECUTOR] Success."
fi

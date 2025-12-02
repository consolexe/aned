#!/usr/bin/env bash
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
MODEL="${1:-qwen2.5:3b}"
SLEEP_SECONDS=10

echo "[AGENT_LOOP] Starting persistent agent. Model: $MODEL"

while true; do
  # load memory (simple)
  MEM_SNIPPET=$(tail -n 200 "$ROOT/core/memory.txt" 2>/dev/null || true)

  # Ask model what to do if idle
  PROMPT_FILE="$ROOT/core/prompt.txt"
  PROMPT="$(cat "$PROMPT_FILE")

# CONTEXT:
$MEM_SNIPPET

# INSTRUCTIONS:
If there are pending tasks in tasks/system_tasks.txt, execute them. Otherwise propose a safe maintenance action or idle check.
Output ONLY commands between ### START and ### END."

  # generate command block
  ollama run "$MODEL" -f "$ROOT/core/prompt.txt" -p "$PROMPT" > "$ROOT/logs/agent_loop_raw.txt" 2>&1 || true

  sed -n '/### START/,/### END/p' "$ROOT/logs/agent_loop_raw.txt" | sed '1d;$d' > "$ROOT/task.sh"

  if [[ -s "$ROOT/task.sh" ]]; then
    echo "[AGENT_LOOP] Running generated task..."
    bash "$ROOT/task.sh" > "$ROOT/logs/agent_loop_exec_$(date +%s).log" 2>&1 || true
  else
    echo "[AGENT_LOOP] No commands generated. Sleeping..."
  fi

  # update simple memory
  echo "$(date): loop ran" >> "$ROOT/core/memory.txt"

  sleep $SLEEP_SECONDS
done

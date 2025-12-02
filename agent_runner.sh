#!/usr/bin/env bash
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
MODEL="${1:-qwen2.5:3b}"
USER_REQUEST="$2"
LOGS="$ROOT/logs"

if [[ -z "$USER_REQUEST" ]]; then
  read -p "Enter task: " USER_REQUEST
fi

PROMPT="You are an agent. Produce a numbered plan; for each step output commands between ### START and ### END. Goal: $USER_REQUEST"
ollama run "$MODEL" <<< "$PROMPT" > "$LOGS/agent_plan.txt" 2>&1 || true

awk '/### START/{flag=1;next}/### END/{flag=0;print "--BLOCK-END--";next}flag{print}' "$LOGS/agent_plan.txt" > "$LOGS/agent_steps_clean.txt"

STEP=0; BLOCK=""
while IFS= read -r line; do
  if [[ "$line" == "--BLOCK-END--" ]]; then
    STEP=$((STEP+1))
    echo "=== Step $STEP ==="
    echo -e "$BLOCK" > "$ROOT/task.sh"
    chmod +x "$ROOT/task.sh"
    echo "Commands:\n$BLOCK"
    read -p "Press Enter to run, 's' skip, 'q' quit: " opt
    if [[ "$opt" == "q" ]]; then break; fi
    if [[ "$opt" != "s" ]]; then
      bash "$ROOT/task.sh" > "$LOGS/agent_step_${STEP}.log" 2>&1
      RC=$?
      if [[ $RC -ne 0 ]]; then
        echo "Step failed; invoking autofix..."
        bash "$ROOT/core/autofix.sh" "$LOGS/agent_step_${STEP}.log" "$ROOT/task.sh"
      fi
    fi
    BLOCK=""
  else
    BLOCK+="$line\n"
  fi
done < "$LOGS/agent_steps_clean.txt"

echo "[AGENT_RUNNER] Finished."

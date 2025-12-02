#!/usr/bin/env bash
# AI-Assistant - entrypoint

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CORE="$ROOT_DIR/core"
MODULES="$ROOT_DIR/modules"
LOGS="$ROOT_DIR/logs"

mkdir -p "$CORE" "$MODULES" "$LOGS"

echo "AI-Assistant (fresh)"
echo "1) Run generator -> executor (interactive)"
echo "2) Start persistent agent (background loop)"
echo "3) Run agent once (single multi-step run)"
echo "4) Add cron task"
echo "5) Show logs dir"
echo "6) Reset memory"
echo "0) Exit"
read -p "Choose: " CH

case "$CH" in
  1)
    read -p "Model (ex: qwen2.5:3b): " MODEL
    read -p "Task: " TASK
    bash "$CORE/generator.sh" "$MODEL" "$TASK"
    bash "$CORE/executor.sh"
    ;;
  2)
    echo "Starting persistent agent (in background)..."
    nohup bash "$CORE/agent_loop.sh" > "$LOGS/agent_nohup.log" 2>&1 &
    echo "Agent started, logs -> $LOGS/agent_nohup.log"
    ;;
  3)
    read -p "Model (ex: qwen2.5:3b): " MODEL
    read -p "Task: " TASK
    bash "$CORE/agent_runner.sh" "$MODEL" "$TASK"
    ;;
  4)
    read -p "Cron (e.g. 0 8 * * *): " CRON
    read -p "Command: " CMD
    read -p "Tag: " TAG
    sudo bash "$MODULES/ai_cron.sh" add "$CRON" "$CMD" "$TAG"
    ;;
  5)
    ls -la "$LOGS" || true
    ;;
  6)
    bash "$CORE/reset_memory.sh"
    ;;
  0) exit 0 ;;
  *) echo "Bye" ;;
esac

AI-Assistant (from-scratch scaffold)
===================================

This project is a minimal, extendable AI-driven assistant scaffold built to evolve.
You asked for a new program built from scratch and improved gradually; Telegram bot excluded.

Quick start:
1. unzip and cd into folder
2. make scripts executable: chmod +x *.sh core/*.sh modules/*.sh
3. run ./menu.sh

Dependencies (recommended):
- ollama CLI (or adapt generator to your local LLM CLI)
- jq, curl, lynx, sqlite3, python3, pip

Structure:
- menu.sh            - interactive entrypoint
- core/              - core logic (generator, executor, agent loop, prompt, memory)
- modules/           - helper modules (web_read, ai_cron, memory storage)
- setup.sh           - install basic deps

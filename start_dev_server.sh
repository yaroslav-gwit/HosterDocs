#!/usr/bin/env bash

cd ~/HosterDocs/
tmux new-session -s root -d "venv/bin/mkdocs serve --dev-addr 0.0.0.0:8000 ; read ;"

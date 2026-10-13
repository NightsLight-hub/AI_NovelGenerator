BACKEND_PORT ?= 8200
FRONTEND_PORT ?= 3300
PYTHON := .venv/bin/python
API_BASE := http://127.0.0.1:$(BACKEND_PORT)

.PHONY: up

SHELL := /bin/bash

# 前台同时启动后端和前端开发服务，Ctrl-C 会一起停止。
up:
	@test -x "$(PYTHON)" || { echo "缺少 .venv，请先创建虚拟环境并安装依赖"; exit 1; }
	@test -d frontend/node_modules || { echo "缺少 frontend/node_modules，请先在 frontend 目录执行 npm install"; exit 1; }
	@if lsof -nP -iTCP:$(BACKEND_PORT) -sTCP:LISTEN >/dev/null 2>&1; then echo "后端端口 $(BACKEND_PORT) 已被占用"; exit 1; fi
	@if lsof -nP -iTCP:$(FRONTEND_PORT) -sTCP:LISTEN >/dev/null 2>&1; then echo "前端端口 $(FRONTEND_PORT) 已被占用"; exit 1; fi
	@echo "后端 http://127.0.0.1:$(BACKEND_PORT)    前端 http://127.0.0.1:$(FRONTEND_PORT)"
	@set -euo pipefail; \
	set -m; \
	backend_pid=; \
	frontend_pid=; \
	cleanup() { \
		status=$$?; \
		trap - INT TERM EXIT; \
		if [[ -n "$$backend_pid" ]]; then kill -TERM -"$$backend_pid" 2>/dev/null || true; fi; \
		if [[ -n "$$frontend_pid" ]]; then kill -TERM -"$$frontend_pid" 2>/dev/null || true; fi; \
		wait 2>/dev/null || true; \
		exit $$status; \
	}; \
	trap cleanup INT TERM EXIT; \
	NOVEL_GENERATOR_BACKEND_PORT="$(BACKEND_PORT)" \
	NOVEL_GENERATOR_FRONTEND_PORT="$(FRONTEND_PORT)" \
	"$(PYTHON)" main.py & \
	backend_pid=$$!; \
	NEXT_PUBLIC_API_BASE="$(API_BASE)" \
	npm --prefix frontend run dev -- --hostname 127.0.0.1 --port "$(FRONTEND_PORT)" & \
	frontend_pid=$$!; \
	wait

#!/bin/bash

echo "🦞 Starting Tarvis Gateway..."

# Check if OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
    echo "❌ OpenClaw is not installed"
    echo "Run: ./scripts/install.sh"
    exit 1
fi

# Check if daemon is running
if systemctl --user is-active --quiet openclaw; then
    echo "ℹ️  OpenClaw daemon is already running"
    echo "To view logs: journalctl --user -u openclaw -f"
    echo "To restart: systemctl --user restart openclaw"
    echo "To stop: systemctl --user stop openclaw"
else
    echo "Starting OpenClaw gateway..."
    openclaw gateway --port 18789 --verbose
fi

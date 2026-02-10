#!/bin/bash

echo "🦞 Tarvis Status Check"
echo "====================="
echo ""

# Check OpenClaw installation
echo "OpenClaw Installation:"
if command -v openclaw &> /dev/null; then
    echo "✅ OpenClaw installed: $(openclaw --version)"
else
    echo "❌ OpenClaw not installed"
fi
echo ""

# Check daemon status
echo "Daemon Status:"
if systemctl --user is-active --quiet openclaw; then
    echo "✅ OpenClaw daemon is running"
    systemctl --user status openclaw --no-pager | head -n 10
else
    echo "❌ OpenClaw daemon is not running"
    echo "Start with: systemctl --user start openclaw"
fi
echo ""

# Check configuration
echo "Configuration:"
if [ -f ~/.openclaw/openclaw.json ]; then
    echo "✅ Configuration file exists: ~/.openclaw/openclaw.json"
    
    # Check for Telegram config
    if grep -q "telegram" ~/.openclaw/openclaw.json; then
        echo "  ✅ Telegram configured"
    else
        echo "  ⚠️  Telegram not configured"
    fi
    
    # Check for Gmail config
    if grep -q "gmail" ~/.openclaw/openclaw.json; then
        echo "  ✅ Gmail configured"
    else
        echo "  ⚠️  Gmail not configured"
    fi
else
    echo "❌ Configuration file not found"
    echo "Run: openclaw onboard"
fi
echo ""

# Check dependencies
echo "Dependencies:"

# Node.js
if command -v node &> /dev/null; then
    echo "✅ Node.js: $(node --version)"
else
    echo "❌ Node.js not installed"
fi

# gcloud
if command -v gcloud &> /dev/null; then
    echo "✅ gcloud: $(gcloud --version | head -n 1)"
else
    echo "⚠️  gcloud not installed (needed for Gmail)"
fi

# gogcli
if command -v gog &> /dev/null; then
    echo "✅ gogcli installed"
else
    echo "⚠️  gogcli not installed (needed for Gmail)"
fi

# Tailscale
if command -v tailscale &> /dev/null; then
    echo "✅ Tailscale: $(tailscale version | head -n 1)"
    if tailscale status &> /dev/null; then
        echo "  ✅ Tailscale connected"
    else
        echo "  ⚠️  Tailscale not connected"
    fi
else
    echo "⚠️  Tailscale not installed (needed for Gmail webhooks)"
fi

# obsidian-cli
if command -v obsidian-cli &> /dev/null; then
    echo "✅ obsidian-cli installed"
else
    echo "⚠️  obsidian-cli not installed (needed for Obsidian)"
fi

echo ""
echo "Run 'openclaw doctor' for detailed diagnostics"

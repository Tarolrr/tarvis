#!/bin/bash
set -e

echo "🦞 Tarvis Installation Script"
echo "=============================="
echo ""

# Check Node.js version
echo "Checking Node.js version..."
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
    echo "❌ Node.js version 22 or higher is required"
    echo "Current version: $(node --version)"
    echo "Please install Node.js 22+ and try again"
    exit 1
fi
echo "✅ Node.js $(node --version) detected"
echo ""

# Install OpenClaw
echo "Installing OpenClaw..."
npm install -g openclaw@latest
echo "✅ OpenClaw installed"
echo ""

# Verify installation
echo "Verifying installation..."
openclaw --version
echo ""

# Run onboarding
echo "Starting OpenClaw onboarding wizard..."
echo "This will guide you through:"
echo "  - Model provider setup (Google/OpenAI/Anthropic)"
echo "  - Authentication configuration"
echo "  - Daemon service installation"
echo ""
read -p "Press Enter to continue..."

openclaw onboard --install-daemon

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Configure Telegram: See docs/setup-guide.md"
echo "2. Configure Gmail: Run 'openclaw webhooks gmail setup --account your@email.com'"
echo "3. Configure Obsidian: Run 'npm install -g obsidian-cli'"
echo "4. Start the gateway: 'openclaw gateway --port 18789'"
echo ""
echo "For detailed instructions, see: docs/setup-guide.md"

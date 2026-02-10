#!/bin/bash

echo "🦞 Tarvis - Telegram Setup"
echo "=========================="
echo ""

echo "To set up Telegram integration:"
echo ""
echo "1. Create a bot with BotFather:"
echo "   - Open Telegram and search for @BotFather"
echo "   - Send: /newbot"
echo "   - Follow the prompts to name your bot"
echo "   - Save the bot token you receive"
echo ""
echo "2. Configure the bot token:"
echo ""

read -p "Enter your Telegram bot token: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    echo "❌ No token provided"
    exit 1
fi

echo ""
read -p "Enter your Telegram username (without @): " USERNAME

if [ -z "$USERNAME" ]; then
    echo "❌ No username provided"
    exit 1
fi

# Create or update config
CONFIG_FILE=~/.openclaw/openclaw.json

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating new configuration file..."
    mkdir -p ~/.openclaw
    cat > "$CONFIG_FILE" <<EOF
{
  "channels": {
    "telegram": {
      "botToken": "$BOT_TOKEN",
      "allowFrom": ["$USERNAME"],
      "dm": {
        "policy": "pairing"
      }
    }
  }
}
EOF
else
    echo "⚠️  Configuration file already exists"
    echo "Please manually add Telegram configuration to: $CONFIG_FILE"
    echo ""
    echo "Add this section:"
    echo ""
    cat <<EOF
{
  "channels": {
    "telegram": {
      "botToken": "$BOT_TOKEN",
      "allowFrom": ["$USERNAME"],
      "dm": {
        "policy": "pairing"
      }
    }
  }
}
EOF
    echo ""
    exit 0
fi

echo ""
echo "✅ Telegram configuration saved to: $CONFIG_FILE"
echo ""
echo "Next steps:"
echo "1. Start the gateway: openclaw gateway --port 18789"
echo "2. Open Telegram and find your bot"
echo "3. Send a message to test"
echo "4. If pairing is enabled, approve with: openclaw pairing approve telegram <code>"

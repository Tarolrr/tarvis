# Tarvis Setup Guide

This guide walks you through setting up Tarvis from scratch.

## Step 1: System Prerequisites

### Install Node.js (≥22)

Check your Node version:
```bash
node --version
```

If you need to install or upgrade Node.js:
```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 22
nvm use 22
```

### Install pnpm (optional but recommended)

```bash
npm install -g pnpm
```

## Step 2: Install OpenClaw

```bash
npm install -g openclaw@latest
```

Verify installation:
```bash
openclaw --version
```

## Step 3: Initial Onboarding

Run the onboarding wizard:
```bash
openclaw onboard --install-daemon
```

This wizard will:
1. Set up your AI model provider (Google, OpenAI, Anthropic, etc.)
2. Configure authentication
3. Install the Gateway daemon service
4. Set up initial security settings

### Model Selection

OpenClaw supports multiple AI providers:
- **Google** (Gemini models via OAuth)
- **OpenAI** (GPT models via API key)
- **Anthropic** (Claude models via API key)
- **OpenRouter** (Access to multiple models)

Choose based on your preference and budget.

## Step 4: Configure Telegram Integration

### Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` command
3. Follow the prompts to name your bot
4. Save the bot token you receive

### Configure OpenClaw

Option 1 - Environment variable:
```bash
export TELEGRAM_BOT_TOKEN="your-bot-token-here"
```

Option 2 - Configuration file (`~/.openclaw/openclaw.json`):
```json
{
  "channels": {
    "telegram": {
      "botToken": "your-bot-token-here",
      "allowFrom": ["your-telegram-username"]
    }
  }
}
```

### Security Settings

For DM security, configure pairing mode:
```json
{
  "channels": {
    "telegram": {
      "botToken": "your-bot-token-here",
      "dm": {
        "policy": "pairing",
        "allowFrom": ["your-telegram-username"]
      }
    }
  }
}
```

## Step 5: Configure Gmail Integration

### Prerequisites

1. **Install gcloud CLI**:
   ```bash
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   gcloud init
   ```

2. **Install gogcli**:
   ```bash
   # Visit https://gogcli.sh/ for installation instructions
   go install github.com/gogcli/gog@latest
   ```

3. **Install Tailscale**:
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   tailscale up
   ```

### Run Gmail Setup Wizard

```bash
openclaw webhooks gmail setup --account your-email@gmail.com
```

This will:
- Set up Google Cloud Pub/Sub
- Configure Gmail watch
- Set up webhook handlers
- Configure Tailscale Funnel for secure access

### Manual Configuration

If you prefer manual setup, edit `~/.openclaw/openclaw.json`:

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-secure-token-here",
    "presets": ["gmail"],
    "gmail": {
      "account": "your-email@gmail.com",
      "model": "openai/gpt-4o-mini",
      "thinking": "off"
    }
  }
}
```

## Step 6: Configure Obsidian Integration

### Install obsidian-cli

```bash
npm install -g obsidian-cli
```

### Set Default Vault

```bash
obsidian-cli set-default "your-vault-name"
```

Verify:
```bash
obsidian-cli print-default
```

### Install OpenClaw Obsidian Skill

```bash
pnpm dlx add-skill https://github.com/openclaw/openclaw/obsidian
```

### Configure in OpenClaw

The Obsidian skill will be automatically available to your assistant. You can now ask it to:
- Search notes: "Search my Obsidian vault for notes about AI"
- Create notes: "Create a new note called 'Meeting Notes' in my vault"
- Move/rename notes: "Rename the note 'Draft' to 'Final Version'"

## Step 7: Start the Gateway

### Start Manually

```bash
openclaw gateway --port 18789 --verbose
```

### Access Control UI

Open your browser to: http://127.0.0.1:18789/

The Control UI provides:
- Chat interface
- Configuration editor
- Session management
- Node pairing
- System diagnostics

### Run as Background Service

The daemon was installed during onboarding. Check status:

```bash
# On Linux with systemd
systemctl --user status openclaw

# Start the service
systemctl --user start openclaw

# Enable auto-start on boot
systemctl --user enable openclaw

# View logs
journalctl --user -u openclaw -f
```

## Step 8: Test Your Setup

### Send a Test Message via Telegram

1. Open Telegram
2. Find your bot (search for the name you gave it)
3. Send a message: "Hello Tarvis!"
4. If pairing is enabled, approve the pairing code:
   ```bash
   openclaw pairing approve telegram <code>
   ```

### Test Gmail Integration

Send yourself an email and watch for the webhook trigger in the logs:
```bash
journalctl --user -u openclaw -f
```

### Test Obsidian

Ask your assistant:
"Search my Obsidian vault for recent notes"

## Step 9: Advanced Configuration

### Configure Security

Edit `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "telegram": {
      "allowFrom": ["+1234567890", "username"],
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    }
  },
  "messages": {
    "groupChat": {
      "mentionPatterns": ["@tarvis", "@bot"]
    }
  }
}
```

### Set Up Remote Access

For secure remote access via Tailscale:

```json
{
  "gateway": {
    "tailscale": {
      "enabled": true,
      "funnel": true
    }
  }
}
```

### Configure Model Failover

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o",
        "fallbacks": [
          "openai/gpt-4o-mini",
          "openrouter/meta-llama/llama-3.3-70b-instruct"
        ]
      }
    }
  }
}
```

## Troubleshooting

### Run Diagnostics

```bash
openclaw doctor
```

### Check Logs

```bash
journalctl --user -u openclaw -f
```

### Common Issues

**Issue**: Gateway won't start
- Check if port 18789 is already in use
- Verify Node.js version (must be ≥22)

**Issue**: Telegram bot not responding
- Verify bot token is correct
- Check if bot is approved in pairing mode
- Review allowFrom configuration

**Issue**: Gmail integration not working
- Verify gcloud and gogcli are installed
- Check Tailscale is running
- Review webhook configuration

## Next Steps

- Explore the [Configuration Reference](configuration.md)
- Learn about [Integration Options](integrations.md)
- Review [Security Best Practices](security.md)

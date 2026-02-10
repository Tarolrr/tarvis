# Tarvis Quick Start

Get Tarvis up and running in minutes.

## Prerequisites

- Linux system
- Node.js ≥ 22
- Git

## Installation

### 1. Install OpenClaw

```bash
./scripts/install.sh
```

This will:
- Check Node.js version
- Install OpenClaw globally
- Run the onboarding wizard
- Install the daemon service

### 2. Set Up Telegram (Recommended First Integration)

```bash
./scripts/setup-telegram.sh
```

Or manually:
1. Create bot with [@BotFather](https://t.me/botfather)
2. Add token to `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "telegram": {
      "botToken": "your-token",
      "allowFrom": ["tarolrr"]
    }
  }
}
```

### 3. Start the Gateway

```bash
./scripts/start.sh
```

Or manually:
```bash
openclaw gateway --port 18789
```

Access Control UI: http://127.0.0.1:18789/

### 4. Test Telegram

1. Open Telegram
2. Find your bot
3. Send: "Hello Tarvis!"
4. If pairing mode is on: `openclaw pairing approve telegram <code>`

## Optional Integrations

### Gmail

```bash
# Install prerequisites
curl https://sdk.cloud.google.com | bash
go install github.com/gogcli/gog@latest
curl -fsSL https://tailscale.com/install.sh | sh

# Run setup wizard
openclaw webhooks gmail setup --account your@email.com
```

### Obsidian

```bash
# Install obsidian-cli
npm install -g obsidian-cli

# Set default vault
obsidian-cli set-default "YourVaultName"

# Install skill
pnpm dlx add-skill https://github.com/openclaw/openclaw/obsidian
```

## Check Status

```bash
./scripts/status.sh
```

Or:
```bash
openclaw doctor
systemctl --user status openclaw
```

## View Logs

```bash
journalctl --user -u openclaw -f
```

## Common Commands

```bash
# Send a message
openclaw message send --to +1234567890 --message "Hello"

# Talk to assistant
openclaw agent --message "What's the weather?" --thinking high

# Restart daemon
systemctl --user restart openclaw

# Stop daemon
systemctl --user stop openclaw
```

## Next Steps

- Read [Setup Guide](docs/setup-guide.md) for detailed instructions
- Review [Configuration Reference](docs/configuration.md)
- Explore [Integration Options](docs/integrations.md)
- Check [Security Best Practices](docs/security.md)

## Troubleshooting

**Gateway won't start**:
```bash
openclaw doctor
journalctl --user -u openclaw -f
```

**Telegram not responding**:
- Verify bot token
- Check pairing approval
- Review allowFrom config

**Need help?**:
- [OpenClaw Docs](https://docs.openclaw.ai/)
- [GitHub Issues](https://github.com/openclaw/openclaw/issues)

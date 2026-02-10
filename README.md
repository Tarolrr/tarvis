# Tarvis

**Tarvis** (from **Jarvis** + **tarolrr**) - Your personal AI assistant powered by OpenClaw.

## Overview

Tarvis is a self-hosted AI assistant that integrates with your daily tools and runs in the background to help manage your digital life.

## Features

- **Telegram Integration**: Control Tarvis through Telegram messages
- **Gmail Integration**: Monitor and manage your inbox with AI-powered email triage
- **Obsidian Integration**: Manage your notes and knowledge base
- **Background Service**: Runs as a daemon, always available
- **Multi-channel Support**: Interact through various messaging platforms

## Architecture

Tarvis is built on [OpenClaw](https://openclaw.ai/), an open-source personal AI assistant platform that:
- Runs on your own hardware (self-hosted)
- Supports multiple messaging channels simultaneously
- Provides agent-native capabilities with tool use and memory
- Offers multi-agent routing and session management

## Prerequisites

- Node.js ≥ 22
- npm or pnpm
- Git
- Google Cloud account (for Gmail integration)
- Telegram account
- Tailscale (for secure remote access)

## Deployment Options

Tarvis can run in two modes:

### Option 1: Local Machine (Quick Start)
Run Tarvis on your local machine for testing and development.

### Option 2: GCP Cloud (Autonomous 24/7)
Deploy Tarvis to Google Cloud Platform for always-on autonomous operation.

**Recommended**: Start local, then deploy to GCP for production use.

## Local Installation

### 1. Install OpenClaw

```bash
npm install -g openclaw@latest
```

### 2. Run Onboarding Wizard

```bash
openclaw onboard --install-daemon
```

This will:
- Set up the OpenClaw Gateway
- Install the daemon service (systemd on Linux)
- Guide you through initial configuration

### 3. Configure Integrations

#### Telegram
Set your Telegram bot token:
```bash
export TELEGRAM_BOT_TOKEN="your-bot-token"
```

Or add to `~/.openclaw/openclaw.json`:
```json
{
  "channels": {
    "telegram": {
      "botToken": "your-bot-token"
    }
  }
}
```

#### Gmail
Run the Gmail setup wizard:
```bash
openclaw webhooks gmail setup --account your-email@gmail.com
```

#### Obsidian
Install the Obsidian skill:
```bash
pnpm dlx add-skill https://github.com/openclaw/openclaw/obsidian
```

### 4. Start the Gateway

```bash
openclaw gateway --port 18789
```

Access the Control UI at: http://127.0.0.1:18789/

## GCP Deployment (Autonomous 24/7)

Deploy Tarvis to run autonomously on Google Cloud Platform.

### Quick Deploy

```bash
./scripts/deploy-gcp.sh
```

This automated script will:
1. Create a GCP project
2. Set up a Compute Engine VM (e2-small, ~$13/month)
3. Install Docker and OpenClaw
4. Guide you through configuration

### Manual Deployment

See the comprehensive guide: [docs/gcp-deployment.md](docs/gcp-deployment.md)

### Integrations on GCP

- **Telegram**: Works out of the box (bot connects to Telegram servers)
- **Gmail**: Requires Pub/Sub setup (automated via wizard)
- **Obsidian**: Multiple options for remote access (see [scripts/obsidian-remote.md](scripts/obsidian-remote.md))

### Access Your GCP Instance

```bash
# SSH tunnel to Control UI
gcloud compute ssh tarvis-gateway --zone=us-central1-a -- -L 18789:127.0.0.1:18789

# Then open: http://127.0.0.1:18789/
```

Or use Tailscale for permanent access.

## Configuration

Configuration is stored in `~/.openclaw/openclaw.json`. See `docs/configuration.md` for detailed setup options.

## Usage

### Send a Message
```bash
openclaw message send --to +1234567890 --message "Hello from Tarvis"
```

### Talk to the Assistant
```bash
openclaw agent --message "What's on my calendar today?" --thinking high
```

### Check Status
```bash
openclaw doctor
```

## Project Structure

```
tarvis/
├── README.md                    # This file
├── QUICKSTART.md               # Quick start guide
├── NEXT_STEPS.md               # Next steps after setup
├── docs/                       # Documentation
│   ├── setup-guide.md         # Detailed local setup
│   ├── gcp-deployment.md      # GCP deployment guide
│   ├── building-openclaw-image.md  # Building Docker image from source
│   ├── configuration.md       # Configuration reference
│   ├── integrations.md        # Integration guides
│   └── security.md            # Security best practices
├── scripts/                    # Helper scripts
│   ├── install.sh             # Install OpenClaw locally
│   ├── deploy-gcp.sh          # Deploy to GCP
│   ├── start.sh               # Start local gateway
│   ├── status.sh              # Check system status
│   ├── setup-telegram.sh      # Configure Telegram
│   └── obsidian-remote.md     # Obsidian remote access guide
└── .gitignore                 # Git ignore rules
```

## Security

Tarvis runs on your local machine and connects to messaging services. Key security features:

- **DM Pairing**: Unknown senders must be approved before they can interact
- **Allowlists**: Control who can send messages to your assistant
- **Local Storage**: All data stays on your machine
- **Encrypted Connections**: Secure communication with external services

See `docs/security.md` for more details.

## Troubleshooting

Run the diagnostic tool:
```bash
openclaw doctor
```

Check logs:
```bash
journalctl --user -u openclaw -f
```

## Resources

- [OpenClaw Documentation](https://docs.openclaw.ai/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Telegram Bot Setup](https://docs.openclaw.ai/channels/telegram)
- [Gmail Integration](https://docs.openclaw.ai/automation/gmail-pubsub)

## License

MIT

## Author

tarolrr

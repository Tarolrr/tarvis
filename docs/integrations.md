# Tarvis Integration Guide

This guide covers detailed setup for each integration.

## Telegram Integration

### Creating Your Bot

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot`
3. Choose a name (e.g., "Tarvis Assistant")
4. Choose a username (e.g., "tarvis_tarolrr_bot")
5. Save the bot token provided

### Configuration

Add to `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "telegram": {
      "botToken": "your-bot-token-here",
      "allowFrom": ["tarolrr"],
      "dm": {
        "policy": "pairing"
      }
    }
  }
}
```

### Usage Examples

**Basic conversation**:
```
You: Hello Tarvis!
Tarvis: Hello! How can I help you today?
```

**Task management**:
```
You: Remind me to call John at 3pm
Tarvis: I'll remind you to call John at 3pm today.
```

**Information queries**:
```
You: What's the weather like today?
Tarvis: [Provides weather information]
```

## Gmail Integration

### Prerequisites Setup

#### 1. Install gcloud CLI

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
gcloud auth login
```

#### 2. Install gogcli

```bash
# Install Go if needed
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install gogcli
go install github.com/gogcli/gog@latest
export PATH=$PATH:~/go/bin
```

Authorize gogcli with your Gmail account:
```bash
gog auth
```

#### 3. Install and Configure Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Automated Setup

Run the Gmail setup wizard:

```bash
openclaw webhooks gmail setup --account your-email@gmail.com
```

This wizard will:
- Create Google Cloud Pub/Sub topic
- Set up Gmail watch
- Configure webhook handlers
- Set up Tailscale Funnel endpoint

### Manual Setup

If you prefer manual configuration:

#### 1. Set up Google Cloud Project

```bash
# Set your project
gcloud config set project your-project-id

# Enable required APIs
gcloud services enable gmail.googleapis.com pubsub.googleapis.com

# Create Pub/Sub topic
gcloud pubsub topics create gog-gmail-watch

# Grant Gmail permission to publish
gcloud pubsub topics add-iam-policy-binding gog-gmail-watch \
  --member=serviceAccount:gmail-api-push@system.gserviceaccount.com \
  --role=roles/pubsub.publisher
```

#### 2. Start Gmail Watch

```bash
gog gmail watch start \
  --account your-email@gmail.com \
  --label INBOX \
  --topic projects/your-project-id/topics/gog-gmail-watch
```

#### 3. Configure OpenClaw

Add to `~/.openclaw/openclaw.json`:

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-secure-token",
    "presets": ["gmail"],
    "gmail": {
      "account": "your-email@gmail.com",
      "model": "openai/gpt-4o-mini",
      "thinking": "off",
      "serve": {
        "bind": "127.0.0.1",
        "port": 8788,
        "path": "/gmail-pubsub"
      },
      "tailscale": {
        "enabled": true,
        "path": "/gmail-pubsub"
      }
    }
  }
}
```

### Usage Examples

Once configured, Tarvis will:

1. **Monitor your inbox**: Receive notifications for new emails
2. **Triage emails**: Identify important messages
3. **Summarize content**: Provide email summaries
4. **Draft replies**: Help compose responses (with your approval)

Example workflow:
```
[New email arrives]
Tarvis (via Telegram): New email from john@example.com
Subject: Project Update
Summary: John is asking about the Q1 report deadline...

You: Draft a reply saying it's due next Friday
Tarvis: Here's a draft reply:
"Hi John, The Q1 report is due next Friday..."
Should I send this?

You: Yes, send it
Tarvis: Email sent!
```

## Obsidian Integration

### Prerequisites

#### 1. Install obsidian-cli

```bash
npm install -g obsidian-cli
```

#### 2. Configure Your Vault

Set your default vault:
```bash
obsidian-cli set-default "YourVaultName"
```

Verify:
```bash
obsidian-cli print-default
obsidian-cli print-default --path-only
```

### Install OpenClaw Obsidian Skill

```bash
pnpm dlx add-skill https://github.com/openclaw/openclaw/obsidian
```

### Vault Structure

Obsidian vaults are just folders with Markdown files:

```
YourVault/
├── Daily Notes/
│   ├── 2025-02-10.md
│   └── 2025-02-11.md
├── Projects/
│   ├── Tarvis.md
│   └── Work.md
├── Resources/
│   └── Articles.md
└── .obsidian/
    └── (config files)
```

### Usage Examples

**Search notes**:
```
You: Search my Obsidian vault for notes about AI
Tarvis: I found 3 notes mentioning AI:
1. Projects/Tarvis.md
2. Resources/Articles.md
3. Daily Notes/2025-02-10.md
```

**Create notes**:
```
You: Create a new note called "Meeting Notes" with today's date
Tarvis: Created note "Meeting Notes/2025-02-10.md"
```

**Search content**:
```
You: Find all notes mentioning "deadline"
Tarvis: Found "deadline" in:
- Projects/Work.md (line 15): "Project deadline is Friday"
- Daily Notes/2025-02-08.md (line 3): "Reminder: deadline approaching"
```

**Move/rename notes**:
```
You: Rename "Draft Ideas" to "Final Proposal"
Tarvis: Renamed note and updated all wikilinks
```

### Advanced: Custom Workflows

You can create custom workflows that combine Obsidian with other integrations:

**Email to Obsidian**:
```
You: Save that last email from John to my Obsidian vault
Tarvis: Created note "Emails/John - Project Update.md" with email content
```

**Calendar to Obsidian**:
```
You: Create a daily note with today's calendar events
Tarvis: Created "Daily Notes/2025-02-10.md" with your calendar
```

## Calendar Integration (Future)

While not yet implemented, calendar integration is planned for:
- Google Calendar
- Outlook Calendar
- CalDAV

This will enable:
- Event summaries
- Reminder notifications
- Schedule management
- Meeting preparation

## Custom Integrations

### Webhooks

You can create custom webhooks for any service:

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-token",
    "mappings": [
      {
        "match": {
          "path": "github"
        },
        "action": "agent",
        "messageTemplate": "GitHub event: {{event.type}}\nRepo: {{event.repo}}"
      }
    ]
  }
}
```

### Skills

OpenClaw supports custom skills. Create your own in `~/.openclaw/skills/`:

```typescript
// ~/.openclaw/skills/custom-skill/index.ts
export default {
  name: 'custom-skill',
  description: 'My custom skill',
  tools: [
    {
      name: 'do_something',
      description: 'Does something useful',
      parameters: {
        type: 'object',
        properties: {
          input: { type: 'string' }
        }
      },
      handler: async (params) => {
        // Your logic here
        return { result: 'Done!' };
      }
    }
  ]
};
```

## Integration Best Practices

1. **Start simple**: Begin with one integration (Telegram) before adding others
2. **Test incrementally**: Verify each integration works before moving to the next
3. **Use pairing mode**: Protect your assistant from unauthorized access
4. **Monitor logs**: Watch for errors during initial setup
5. **Set up fallbacks**: Configure backup models for reliability
6. **Document your workflows**: Keep notes on how you use each integration
7. **Regular maintenance**: Update tokens and credentials as needed

## Troubleshooting

### Telegram Not Responding

- Verify bot token is correct
- Check pairing approval: `openclaw pairing approve telegram <code>`
- Review allowFrom configuration
- Check logs: `journalctl --user -u openclaw -f`

### Gmail Integration Issues

- Verify gcloud is authenticated: `gcloud auth list`
- Check gogcli authorization: `gog auth`
- Verify Tailscale is running: `tailscale status`
- Check webhook endpoint is accessible
- Review Pub/Sub topic permissions

### Obsidian Not Working

- Verify vault path: `obsidian-cli print-default --path-only`
- Check obsidian-cli is installed: `which obsidian-cli`
- Ensure Obsidian app is installed (for URI handlers)
- Verify vault permissions

### General Debugging

```bash
# Check OpenClaw status
openclaw doctor

# View detailed logs
journalctl --user -u openclaw -f

# Test agent directly
openclaw agent --message "test" --thinking high

# Check configuration
cat ~/.openclaw/openclaw.json | jq
```

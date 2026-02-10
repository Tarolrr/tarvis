# Tarvis GCP Deployment Guide

Deploy Tarvis to run autonomously on Google Cloud Platform.

## Overview

Running Tarvis on GCP provides:
- **24/7 availability**: Always-on assistant
- **Autonomous operation**: No need for your local machine to be running
- **Scalable resources**: Adjust VM size as needed
- **Secure access**: SSH tunnels or Tailscale for remote access

## Architecture

```
┌─────────────────────────────────────────┐
│         GCP Compute Engine VM           │
│  ┌───────────────────────────────────┐  │
│  │   Docker Container (OpenClaw)     │  │
│  │   - Gateway (port 18789)          │  │
│  │   - Telegram integration          │  │
│  │   - Gmail integration (gog)       │  │
│  │   - Persistent storage            │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
           ↓                    ↑
    [Telegram Bot]      [SSH Tunnel/Tailscale]
    [Gmail Pub/Sub]     [Your Laptop]
```

## Prerequisites

- GCP account with billing enabled
- `gcloud` CLI installed on your local machine
- Basic SSH knowledge
- API credentials (Telegram bot token, AI provider API keys)

## Cost Estimate

- **e2-micro** (free tier eligible): 2 vCPU, 1GB RAM - Free for 1 instance
- **e2-small**: 2 vCPU, 2GB RAM - ~$13/month
- **e2-medium**: 2 vCPU, 4GB RAM - ~$27/month

**Recommended**: Start with e2-small (2GB RAM)

## Step-by-Step Deployment

### 1. Install gcloud CLI (Local Machine)

```bash
# Install gcloud
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize and authenticate
gcloud init
gcloud auth login
```

### 2. Create GCP Project

```bash
# Create project
gcloud projects create tarvis-assistant --name="Tarvis Assistant"

# Set as active project
gcloud config set project tarvis-assistant

# Enable billing (do this in console: https://console.cloud.google.com/billing)

# Enable Compute Engine API
gcloud services enable compute.googleapis.com
```

### 3. Create the VM

```bash
gcloud compute instances create tarvis-gateway \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --boot-disk-size=20GB \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --tags=tarvis
```

**VM Specs**:
- Name: `tarvis-gateway`
- Zone: `us-central1-a` (change to your preferred region)
- Machine: `e2-small` (2 vCPU, 2GB RAM)
- Disk: 20GB SSD
- OS: Debian 12

### 4. SSH into the VM

```bash
gcloud compute ssh tarvis-gateway --zone=us-central1-a
```

### 5. Install Docker on VM

```bash
# Update system
sudo apt-get update
sudo apt-get install -y git curl ca-certificates

# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes
exit
```

Re-connect:
```bash
gcloud compute ssh tarvis-gateway --zone=us-central1-a
```

Verify Docker:
```bash
docker --version
docker compose version
```

### 6. Clone OpenClaw Repository

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

### 7. Create Persistent Directories

```bash
mkdir -p ~/.openclaw
mkdir -p ~/.openclaw/workspace
```

### 8. Configure Environment Variables

Create `.env` file:

```bash
cat > .env << 'EOF'
OPENCLAW_IMAGE=openclaw:latest
OPENCLAW_GATEWAY_TOKEN=CHANGE_ME_NOW
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_CONFIG_DIR=/home/$USER/.openclaw
OPENCLAW_WORKSPACE_DIR=/home/$USER/.openclaw/workspace
GOG_KEYRING_PASSWORD=CHANGE_ME_NOW
XDG_CONFIG_HOME=/home/node/.openclaw
EOF
```

**Generate secure tokens**:
```bash
# Generate gateway token
echo "OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)"

# Generate keyring password
echo "GOG_KEYRING_PASSWORD=$(openssl rand -hex 32)"
```

Update `.env` with these tokens.

### 9. Create Docker Compose Configuration

The OpenClaw repo includes `docker-compose.yml`. Verify it exists:

```bash
cat docker-compose.yml
```

If you need to customize, ensure it has:
- Port binding to `127.0.0.1:18789` (for SSH tunnel access)
- Volume mounts for persistence
- Required environment variables

### 10. Customize Dockerfile for Required Binaries

Edit `Dockerfile` to include `gog` (for Gmail):

```bash
cat > Dockerfile << 'EOF'
FROM node:22-bookworm

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# Install gog for Gmail integration
RUN curl -L https://github.com/steipete/gog/releases/latest/download/gog_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/gog

# Install goplaces (optional, for Google Places)
RUN curl -L https://github.com/steipete/goplaces/releases/latest/download/goplaces_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/goplaces

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY scripts ./scripts

RUN corepack enable
RUN pnpm install --frozen-lockfile

COPY . .

RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production

CMD ["node","dist/index.js"]
EOF
```

### 11. Build and Launch

```bash
# Build the Docker image (takes 5-10 minutes)
docker compose build

# Start the gateway
docker compose up -d openclaw-gateway

# Verify it's running
docker compose logs -f openclaw-gateway
```

Look for: `[gateway] listening on ws://0.0.0.0:18789`

### 12. Initial Configuration (On VM)

Run onboarding inside the container:

```bash
docker compose exec openclaw-gateway node dist/index.js onboard
```

This will guide you through:
- Model provider setup (OpenAI, Anthropic, Google, etc.)
- Authentication configuration

### 13. Configure Telegram

Create/edit `~/.openclaw/openclaw.json` on the VM:

```bash
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "channels": {
    "telegram": {
      "botToken": "YOUR_TELEGRAM_BOT_TOKEN",
      "allowFrom": ["tarolrr"],
      "dm": {
        "policy": "pairing"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o",
        "fallbacks": ["openai/gpt-4o-mini"]
      },
      "thinking": "medium"
    }
  },
  "gateway": {
    "port": 18789,
    "auth": {
      "token": "YOUR_GATEWAY_TOKEN"
    }
  }
}
EOF
```

Replace:
- `YOUR_TELEGRAM_BOT_TOKEN`: Get from [@BotFather](https://t.me/botfather)
- `YOUR_GATEWAY_TOKEN`: Use the token from `.env`

Restart the container:
```bash
docker compose restart openclaw-gateway
```

### 14. Configure Gmail Integration

Inside the container, run:

```bash
# Authenticate gog with your Gmail
docker compose exec openclaw-gateway gog auth

# Set up Gmail webhook
docker compose exec openclaw-gateway node dist/index.js webhooks gmail setup \
  --account your-email@gmail.com
```

This requires:
- Google Cloud project (can be same as VM project)
- Pub/Sub API enabled
- Tailscale for webhook endpoint (or manual setup)

### 15. Access from Your Laptop

**Option A: SSH Tunnel (Recommended)**

From your local machine:

```bash
gcloud compute ssh tarvis-gateway --zone=us-central1-a -- -L 18789:127.0.0.1:18789
```

Then open: http://127.0.0.1:18789/

**Option B: Tailscale (Better for permanent access)**

On the VM:
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

On your laptop:
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
```

Access via: `http://tarvis-gateway:18789/`

## Obsidian Integration Options

Since Obsidian runs on your local machine, you have two options:

### Option 1: Expose Obsidian via API (Recommended)

Use the Obsidian Local REST API plugin:

1. Install "Local REST API" plugin in Obsidian
2. Configure API key
3. Expose via Tailscale or ngrok
4. Configure OpenClaw to use the API endpoint

### Option 2: Sync Vault to GCP

Sync your Obsidian vault to the GCP VM:

```bash
# On VM, install obsidian-cli
docker compose exec openclaw-gateway npm install -g obsidian-cli

# Sync vault (use git, rclone, or rsync)
# Example with rsync:
rsync -avz ~/Documents/ObsidianVault/ \
  tarvis-gateway:~/.openclaw/obsidian-vault/
```

Then configure obsidian-cli to use the synced vault.

### Option 3: Hybrid Approach (Best)

- Keep Obsidian on your local machine
- Use Tailscale to connect your laptop to the GCP VM
- Install obsidian-cli locally
- Configure OpenClaw to execute obsidian-cli commands via SSH

## Configuration Files Location

All configuration persists in:
- `~/.openclaw/openclaw.json` - Main config
- `~/.openclaw/credentials/` - Channel credentials
- `~/.openclaw/workspace/` - Agent workspace
- `~/.openclaw/sessions/` - Session history

These are mounted from the host VM, so they survive container restarts.

## Maintenance

### View Logs

```bash
docker compose logs -f openclaw-gateway
```

### Restart Gateway

```bash
docker compose restart openclaw-gateway
```

### Update OpenClaw

```bash
cd ~/openclaw
git pull
docker compose build
docker compose up -d
```

### Backup Configuration

```bash
# On VM
tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz ~/.openclaw

# Download to local machine
gcloud compute scp tarvis-gateway:~/openclaw-backup-*.tar.gz . --zone=us-central1-a
```

### Stop Gateway

```bash
docker compose down
```

## Security Best Practices

1. **Keep Gateway on localhost**: Use SSH tunnel or Tailscale for access
2. **Use strong tokens**: Generate with `openssl rand -hex 32`
3. **Enable pairing mode**: Protect Telegram/other channels
4. **Firewall rules**: Don't expose port 18789 publicly
5. **Regular updates**: Keep OpenClaw and Docker updated
6. **Backup regularly**: Backup `~/.openclaw` directory

## Firewall Configuration (If Needed)

If you need to expose ports (not recommended):

```bash
# Create firewall rule
gcloud compute firewall-rules create allow-openclaw \
  --allow tcp:18789 \
  --source-ranges YOUR_IP_ADDRESS/32 \
  --target-tags tarvis

# Better: Don't do this, use SSH tunnel or Tailscale instead
```

## Troubleshooting

### Container won't start

```bash
docker compose logs openclaw-gateway
docker compose exec openclaw-gateway node dist/index.js doctor
```

### Can't access from laptop

```bash
# Verify SSH tunnel is active
lsof -i :18789

# Test connection
curl http://127.0.0.1:18789/health
```

### Gmail integration not working

```bash
# Check gog is installed
docker compose exec openclaw-gateway which gog

# Check gog auth
docker compose exec openclaw-gateway gog auth
```

### Out of memory

Upgrade VM:
```bash
gcloud compute instances stop tarvis-gateway --zone=us-central1-a
gcloud compute instances set-machine-type tarvis-gateway \
  --machine-type=e2-medium \
  --zone=us-central1-a
gcloud compute instances start tarvis-gateway --zone=us-central1-a
```

## Cost Optimization

1. **Use preemptible instances**: 60-91% cheaper (but can be terminated)
2. **Stop when not needed**: `gcloud compute instances stop tarvis-gateway`
3. **Use e2-micro**: Free tier eligible (but only 1GB RAM)
4. **Set up billing alerts**: Monitor spending

## Next Steps

1. Test Telegram integration
2. Set up Gmail monitoring
3. Configure Obsidian access
4. Set up automated backups
5. Configure monitoring/alerts

## Resources

- [OpenClaw GCP Docs](https://docs.openclaw.ai/platforms/gcp)
- [OpenClaw Remote Access](https://docs.openclaw.ai/gateway/remote)
- [GCP Compute Engine](https://cloud.google.com/compute/docs)
- [Tailscale Setup](https://tailscale.com/kb/1017/install)

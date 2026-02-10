# Tarvis

**Tarvis** (from **Jarvis** + **tarolrr**) - Your personal AI assistant powered by OpenClaw, running autonomously 24/7 on Google Cloud Platform.

## Overview

Tarvis is a self-hosted AI assistant that integrates with Telegram, Gmail, and Obsidian. It runs as a Docker container on GCP, providing always-on autonomous operation.

**Key Features:**
- 🤖 **AI-Powered**: Uses Anthropic Claude for intelligent responses
- 💬 **Telegram Integration**: Control via Telegram bot
- 📧 **Gmail Integration**: AI-powered email monitoring and triage
- 📝 **Obsidian Integration**: Manage your knowledge base
- ☁️ **Cloud Deployment**: Runs 24/7 on GCP (~$13/month)
- 🔒 **Secure**: DM pairing, allowlists, encrypted storage

## Quick Start

```bash
# 1. Clone OpenClaw and build image locally
git clone https://github.com/openclaw/openclaw.git
cd openclaw
cp /path/to/tarvis/Dockerfile .
cp /path/to/tarvis/docker-compose.yml .
docker build -t openclaw:latest .

# 2. Push to Container Registry
gcloud services enable containerregistry.googleapis.com
gcloud auth configure-docker
PROJECT_ID=$(gcloud config get-value project)
docker tag openclaw:latest gcr.io/${PROJECT_ID}/openclaw:latest
docker tag openclaw:latest gcr.io/${PROJECT_ID}/openclaw:$(date +%Y%m%d)
docker push gcr.io/${PROJECT_ID}/openclaw:latest
docker push gcr.io/${PROJECT_ID}/openclaw:$(date +%Y%m%d)

# 3. Deploy to GCP
# See docs/gcp-deployment.md for full guide
```

## Documentation Flow

Follow these guides in order:

### 1. Prerequisites
**What you need before starting:**
- Google Cloud account with billing enabled
- Docker installed locally (for building)
- `gcloud` CLI installed and configured
- Telegram account (for bot creation)
- Anthropic API key (or other AI provider)

**Estimated time:** 15 minutes

### 2. Building the Image

**Prerequisites:**
- Docker installed locally (Docker Desktop on Mac/Windows, Docker Engine on Linux)
- `gcloud` CLI configured with authentication
- At least 4GB RAM available on your local machine
- 20GB free disk space

**Build locally (15-20 minutes):**

```bash
# Clone OpenClaw
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Copy Dockerfile and docker-compose.yml from tarvis repo
cp /path/to/tarvis/Dockerfile .
cp /path/to/tarvis/docker-compose.yml .

# Build image (includes gog binary for Gmail)
docker build -t openclaw:latest .
# Or use docker compose
docker compose build

# Enable Container Registry and authenticate
gcloud services enable containerregistry.googleapis.com
gcloud auth configure-docker

# Tag and push to registry
PROJECT_ID=$(gcloud config get-value project)
docker tag openclaw:latest gcr.io/${PROJECT_ID}/openclaw:latest
docker tag openclaw:latest gcr.io/${PROJECT_ID}/openclaw:$(date +%Y%m%d)
docker push gcr.io/${PROJECT_ID}/openclaw:latest
docker push gcr.io/${PROJECT_ID}/openclaw:$(date +%Y%m%d)
```

**Why build locally?**
- No expensive cloud VMs needed for building
- Use your local machine's resources
- Faster iteration during development
- Cost: $0 (vs ~$27/month for e2-medium build VM)

### 3. Deploying to GCP
📖 **Guide:** [`docs/gcp-deployment.md`](docs/gcp-deployment.md)

**What you'll do:**
- Create GCP project and enable APIs
- Create e2-small VM (~$13/month)
- Pull pre-built image from registry
- Configure environment variables
- Launch Docker container

**Estimated time:** 20-30 minutes

### 4. Configuration
📖 **Guides:** 
- [`docs/integrations.md`](docs/integrations.md) - Telegram, Gmail, Obsidian setup
- [`docs/configuration.md`](docs/configuration.md) - Advanced configuration options
- [`docs/security.md`](docs/security.md) - Security best practices

**What you'll do:**
- Create Telegram bot via @BotFather
- Run onboarding wizard (AI provider setup)
- Configure Telegram bot token
- Set up Gmail integration (optional)
- Configure Obsidian access (optional)

**Estimated time:** 15-20 minutes

### 5. Running and Using Tarvis

**Access the Control UI:**
```bash
# SSH tunnel from your local machine
gcloud compute ssh tarvis-gateway --zone=us-central1-a -- -L 18789:127.0.0.1:18789

# Open in browser
open http://127.0.0.1:18789/
```

**Talk to Tarvis via Telegram:**
1. Find your bot in Telegram
2. Send `/start`
3. Start chatting!

**Check Status:**
```bash
# SSH into VM
gcloud compute ssh tarvis-gateway --zone=us-central1-a

# Check container status
docker compose ps

# View logs
docker compose logs -f openclaw-gateway
```

## Architecture

```
┌─────────────────────────────────────────┐
│         GCP Compute Engine VM           │
│         (e2-small, ~$13/month)          │
│  ┌───────────────────────────────────┐  │
│  │   Docker Container (OpenClaw)     │  │
│  │   - Gateway (port 18789)          │  │
│  │   - Telegram integration          │  │
│  │   - Gmail integration (gog)       │  │
│  │   - Persistent storage            │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
           ↓                    ↑
    [Telegram Bot]      [SSH Tunnel]
    [Gmail Pub/Sub]     [Your Laptop]
```

## Cost Breakdown

**Monthly Costs:**
- **VM (e2-small)**: ~$13/month (2 vCPU, 2GB RAM, always-on)
- **Container Registry**: ~$0.03/month (image storage)
- **Anthropic API**: Pay-as-you-go (depends on usage)

**Total**: ~$13-15/month + API usage

**Build Costs**: $0 (build locally, not on cloud)

## Project Structure

```
tarvis/
├── README.md                           # This file
├── Dockerfile                          # OpenClaw Docker image with gog binary
├── docker-compose.yml                  # Docker Compose configuration
├── docs/                               # Documentation
│   ├── gcp-deployment.md              # Deploy to GCP
│   ├── configuration.md               # Configuration reference
│   ├── integrations.md                # Telegram, Gmail, Obsidian setup
│   └── security.md                    # Security best practices
├── scripts/                            # Helper scripts
│   ├── deploy-gcp.sh                  # Automated GCP deployment
│   └── obsidian-remote.md             # Obsidian remote access options
└── .gitignore                         # Git ignore rules
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker compose logs openclaw-gateway

# Common issues:
# - Missing config: Run onboarding wizard
# - Wrong tokens: Check .env file
# - Port conflict: Check if port 18789 is in use
```

### Can't Access Control UI
```bash
# Verify SSH tunnel is running
gcloud compute ssh tarvis-gateway --zone=us-central1-a -- -L 18789:127.0.0.1:18789

# Check container is running
docker compose ps
```

### Telegram Bot Not Responding
1. Verify bot token in `~/.openclaw/openclaw.json`
2. Check container logs for errors
3. Restart container: `docker compose restart openclaw-gateway`

### Gmail Integration Issues
```bash
# Test gog binary
docker compose exec openclaw-gateway gog --version

# Re-authenticate
docker compose exec openclaw-gateway gog auth
```

## Resources

- **OpenClaw Documentation**: https://docs.openclaw.ai/
- **OpenClaw GitHub**: https://github.com/openclaw/openclaw
- **Telegram Bot Setup**: https://docs.openclaw.ai/channels/telegram
- **Gmail Integration**: https://docs.openclaw.ai/automation/gmail-pubsub

## Security

- **DM Pairing**: Unknown senders must be approved
- **Allowlists**: Control who can interact with Tarvis
- **Encrypted Storage**: Credentials stored securely
- **SSH-Only Access**: Control UI only accessible via SSH tunnel

See [`docs/security.md`](docs/security.md) for detailed security practices.

## License

MIT

## Author

tarolrr

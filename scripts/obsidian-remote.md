# Obsidian Remote Access for Tarvis on GCP

Since your Obsidian vault is on your local machine and Tarvis runs on GCP, you need a way to connect them.

## Option 1: Obsidian Local REST API (Recommended)

### Setup

1. **Install Plugin in Obsidian**
   - Open Obsidian Settings
   - Go to Community Plugins
   - Search for "Local REST API"
   - Install and enable it

2. **Configure API**
   - Go to plugin settings
   - Generate an API key
   - Note the port (default: 27123)

3. **Expose via Tailscale**
   
   On your local machine:
   ```bash
   # Install Tailscale
   curl -fsSL https://tailscale.com/install.sh | sh
   tailscale up
   
   # Serve Obsidian API
   tailscale serve https / http://127.0.0.1:27123
   ```

4. **Configure OpenClaw on GCP**
   
   In `~/.openclaw/openclaw.json` on the VM:
   ```json
   {
     "integrations": {
       "obsidian": {
         "type": "rest-api",
         "endpoint": "https://your-machine.your-tailnet.ts.net",
         "apiKey": "your-api-key"
       }
     }
   }
   ```

### Usage

The assistant can now:
- Search notes via API
- Create/update notes
- Read note content

## Option 2: Sync Vault to GCP

### Using Git

1. **Initialize Git in your vault** (local machine):
   ```bash
   cd ~/Documents/ObsidianVault
   git init
   git add .
   git commit -m "Initial commit"
   
   # Push to GitHub (private repo)
   gh repo create obsidian-vault --private --source=.
   git push -u origin main
   ```

2. **Clone on GCP VM**:
   ```bash
   # SSH into VM
   gcloud compute ssh tarvis-gateway --zone=us-central1-a
   
   # Clone vault
   git clone https://github.com/tarolrr/obsidian-vault.git ~/.openclaw/obsidian-vault
   
   # Install obsidian-cli in container
   docker compose exec openclaw-gateway npm install -g obsidian-cli
   ```

3. **Set up auto-sync** (local machine):
   ```bash
   # Create sync script
   cat > ~/sync-obsidian.sh << 'EOF'
   #!/bin/bash
   cd ~/Documents/ObsidianVault
   git add .
   git commit -m "Auto-sync $(date)" || true
   git push
   EOF
   
   chmod +x ~/sync-obsidian.sh
   
   # Add to cron (every 15 minutes)
   (crontab -l 2>/dev/null; echo "*/15 * * * * ~/sync-obsidian.sh") | crontab -
   ```

4. **Pull on GCP** (add to cron on VM):
   ```bash
   # On VM
   cat > ~/sync-obsidian-pull.sh << 'EOF'
   #!/bin/bash
   cd ~/.openclaw/obsidian-vault
   git pull
   EOF
   
   chmod +x ~/sync-obsidian-pull.sh
   (crontab -l 2>/dev/null; echo "*/15 * * * * ~/sync-obsidian-pull.sh") | crontab -
   ```

### Using rclone (for cloud sync)

If you use Obsidian Sync or sync to Google Drive/Dropbox:

```bash
# Install rclone on VM
curl https://rclone.org/install.sh | sudo bash

# Configure rclone
rclone config

# Sync vault
rclone sync gdrive:ObsidianVault ~/.openclaw/obsidian-vault

# Add to cron
(crontab -l 2>/dev/null; echo "*/15 * * * * rclone sync gdrive:ObsidianVault ~/.openclaw/obsidian-vault") | crontab -
```

## Option 3: SSH Reverse Tunnel (Advanced)

Run obsidian-cli on your local machine, accessible from GCP via reverse tunnel.

### Setup

1. **On your local machine**:
   ```bash
   # Install obsidian-cli
   npm install -g obsidian-cli
   
   # Set default vault
   obsidian-cli set-default "YourVault"
   
   # Keep Tailscale running
   tailscale up
   ```

2. **On GCP VM**, configure OpenClaw to SSH to your machine:
   ```json
   {
     "integrations": {
       "obsidian": {
         "type": "ssh-remote",
         "host": "your-machine.your-tailnet.ts.net",
         "command": "obsidian-cli"
       }
     }
   }
   ```

## Option 4: Hybrid - Local Processing

Keep Obsidian operations on your local machine, use Tarvis for everything else.

### Setup

1. **Run a local OpenClaw instance** (just for Obsidian):
   ```bash
   # On local machine
   npm install -g openclaw@latest
   openclaw gateway --port 18790
   ```

2. **Configure GCP Tarvis to forward Obsidian requests**:
   ```json
   {
     "integrations": {
       "obsidian": {
         "type": "forward",
         "endpoint": "https://your-machine.your-tailnet.ts.net:18790"
       }
     }
   }
   ```

## Comparison

| Option | Pros | Cons | Best For |
|--------|------|------|----------|
| REST API | Real-time, no sync lag | Requires local machine running | Active use |
| Git Sync | Simple, version control | 15min sync lag | Async updates |
| rclone | Works with cloud storage | Sync lag, complexity | Cloud users |
| SSH Tunnel | Direct access | Requires local machine | Power users |
| Hybrid | Best of both worlds | Two instances to manage | Advanced setups |

## Recommended Setup

For your use case (Obsidian subscription, local machine):

1. **Use Tailscale** to connect local machine to GCP
2. **Install Obsidian Local REST API plugin**
3. **Expose API via Tailscale Serve**
4. **Configure Tarvis to use the API endpoint**

This gives you:
- Real-time access to your vault
- No sync lag
- Secure connection via Tailscale
- Works with your existing Obsidian setup

## Testing

After setup, test from GCP VM:

```bash
# SSH into VM
gcloud compute ssh tarvis-gateway --zone=us-central1-a

# Test obsidian access
docker compose exec openclaw-gateway node dist/index.js agent \
  --message "Search my Obsidian vault for notes about AI"
```

## Troubleshooting

### Can't connect to local machine

```bash
# Verify Tailscale is running on both machines
tailscale status

# Test connectivity
ping your-machine.your-tailnet.ts.net
```

### API not accessible

```bash
# Check Obsidian plugin is running
curl http://127.0.0.1:27123/vault/

# Check Tailscale serve
tailscale serve status
```

### Git sync conflicts

```bash
# On local machine
cd ~/Documents/ObsidianVault
git pull --rebase
git push
```

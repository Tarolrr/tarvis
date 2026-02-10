#!/bin/bash
set -e

echo "🦞 Tarvis GCP Deployment Script"
echo "================================"
echo ""

# Configuration
PROJECT_ID="tarvis-assistant"
VM_NAME="tarvis-gateway"
ZONE="us-central1-a"
MACHINE_TYPE="e2-small"
DISK_SIZE="20GB"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo -e "${GREEN}✅ gcloud CLI found${NC}"
echo ""

# Step 1: Create or select project
echo "Step 1: GCP Project Setup"
echo "-------------------------"
read -p "Use project ID '$PROJECT_ID'? (y/n): " use_default

if [ "$use_default" != "y" ]; then
    read -p "Enter your GCP project ID: " PROJECT_ID
fi

echo "Creating/selecting project: $PROJECT_ID"
gcloud projects create $PROJECT_ID --name="Tarvis Assistant" 2>/dev/null || echo "Project already exists"
gcloud config set project $PROJECT_ID

echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Enable billing for this project${NC}"
echo "Visit: https://console.cloud.google.com/billing"
read -p "Press Enter after enabling billing..."

# Enable Compute Engine API
echo "Enabling Compute Engine API..."
gcloud services enable compute.googleapis.com

echo -e "${GREEN}✅ Project setup complete${NC}"
echo ""

# Step 2: Create VM
echo "Step 2: Create VM Instance"
echo "--------------------------"
echo "Configuration:"
echo "  Name: $VM_NAME"
echo "  Zone: $ZONE"
echo "  Machine: $MACHINE_TYPE (2 vCPU, 2GB RAM)"
echo "  Disk: $DISK_SIZE"
echo "  Cost: ~\$13/month"
echo ""
read -p "Create VM with these settings? (y/n): " create_vm

if [ "$create_vm" = "y" ]; then
    gcloud compute instances create $VM_NAME \
        --zone=$ZONE \
        --machine-type=$MACHINE_TYPE \
        --boot-disk-size=$DISK_SIZE \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --tags=tarvis
    
    echo -e "${GREEN}✅ VM created successfully${NC}"
else
    echo "Skipping VM creation"
fi

echo ""

# Step 3: Setup instructions
echo "Step 3: VM Setup"
echo "----------------"
echo "Now we'll SSH into the VM and set up OpenClaw"
echo ""
read -p "Press Enter to SSH into the VM..."

# Create setup script to run on VM
cat > /tmp/tarvis-vm-setup.sh << 'VMSCRIPT'
#!/bin/bash
set -e

echo "🦞 Setting up Tarvis on GCP VM"
echo "=============================="
echo ""

# Install Docker
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

echo "✅ Docker installed"
echo ""
echo "⚠️  You need to log out and back in for Docker group changes"
echo ""
echo "After reconnecting, run:"
echo "  cd ~"
echo "  git clone https://github.com/openclaw/openclaw.git"
echo "  cd openclaw"
echo "  mkdir -p ~/.openclaw ~/.openclaw/workspace"
echo ""
echo "Then create .env file with:"
echo "  OPENCLAW_GATEWAY_TOKEN=\$(openssl rand -hex 32)"
echo "  GOG_KEYRING_PASSWORD=\$(openssl rand -hex 32)"
echo ""
echo "See docs/gcp-deployment.md for full instructions"
VMSCRIPT

# Copy setup script to VM
gcloud compute scp /tmp/tarvis-vm-setup.sh $VM_NAME:~/setup.sh --zone=$ZONE

# SSH into VM
echo ""
echo "Connecting to VM..."
echo "Run: bash ~/setup.sh"
echo ""
gcloud compute ssh $VM_NAME --zone=$ZONE

echo ""
echo "🎉 Deployment initiated!"
echo ""
echo "Next steps:"
echo "1. Complete the setup on the VM (run: bash ~/setup.sh)"
echo "2. Follow the instructions in docs/gcp-deployment.md"
echo "3. Configure Telegram, Gmail, and other integrations"
echo ""
echo "To access the Control UI from your laptop:"
echo "  gcloud compute ssh $VM_NAME --zone=$ZONE -- -L 18789:127.0.0.1:18789"
echo "  Then open: http://127.0.0.1:18789/"

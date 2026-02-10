# Building OpenClaw Docker Image

This guide covers building the OpenClaw Docker image from source and pushing it to Google Container Registry.

## Prerequisites

- Docker installed
- `gcloud` CLI configured
- At least 4GB RAM available for building
- Google Cloud project with Container Registry enabled

## Why Build From Source?

The pre-built image in the registry should work for most users. Build from source if you need to:
- Customize the Dockerfile
- Add additional binaries or dependencies
- Test unreleased OpenClaw features
- Contribute to OpenClaw development

## Build Environment Requirements

**Minimum System Requirements:**
- **RAM**: 4GB (e2-medium on GCP)
- **Disk**: 20GB free space
- **CPU**: 2+ cores recommended

**Note**: Building on e2-micro (1GB RAM) or e2-small (2GB RAM) will fail due to out-of-memory errors during the `pnpm install` step.

## Step 1: Clone OpenClaw Repository

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

## Step 2: Create Dockerfile

The standard OpenClaw Dockerfile works well. Create or verify `Dockerfile`:

```dockerfile
FROM node:22-bookworm

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

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
```

**Note**: The original deployment guide included `gog` binary installation, but this is optional and can be installed separately if needed for Gmail integration.

## Step 3: Create docker-compose.yml

Ensure your `docker-compose.yml` includes build configuration:

```yaml
services:
  openclaw-gateway:
    image: ${OPENCLAW_IMAGE:-openclaw:local}
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN}
      GOG_KEYRING_PASSWORD: ${GOG_KEYRING_PASSWORD}
      XDG_CONFIG_HOME: ${XDG_CONFIG_HOME}
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    ports:
      - "127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}:18789"
      - "127.0.0.1:${OPENCLAW_BRIDGE_PORT:-18790}:18790"
    init: true
    restart: unless-stopped
    command:
      [
        "node",
        "dist/index.js",
        "gateway",
        "--bind",
        "${OPENCLAW_GATEWAY_BIND:-lan}",
        "--port",
        "18789",
      ]
```

## Step 4: Build the Image

```bash
docker compose build
```

**Build Time**: 5-10 minutes on e2-medium (4GB RAM)

**Expected Output:**
- Package installation: ~2-3 minutes
- TypeScript compilation: ~2-3 minutes
- UI build: ~1 minute
- Image export: ~2-3 minutes

## Step 5: Enable Google Container Registry

```bash
# Enable Container Registry API
gcloud services enable containerregistry.googleapis.com

# Configure Docker to use gcloud as credential helper
gcloud auth configure-docker
```

## Step 6: Tag the Image

```bash
# Get your GCP project ID
PROJECT_ID=$(gcloud config get-value project)

# Tag the image
docker tag openclaw:latest gcr.io/${PROJECT_ID}/openclaw:latest
docker tag openclaw:latest gcr.io/${PROJECT_ID}/openclaw:$(date +%Y%m%d)
```

## Step 7: Push to Container Registry

```bash
# Push latest tag
docker push gcr.io/${PROJECT_ID}/openclaw:latest

# Push dated tag (for rollback capability)
docker push gcr.io/${PROJECT_ID}/openclaw:$(date +%Y%m%d)
```

## Step 8: Verify Upload

```bash
# List images in registry
gcloud container images list --repository=gcr.io/${PROJECT_ID}

# List tags for openclaw image
gcloud container images list-tags gcr.io/${PROJECT_ID}/openclaw
```

## Using the Image in Deployment

Update your `.env` file to use the registry image:

```bash
OPENCLAW_IMAGE=gcr.io/YOUR_PROJECT_ID/openclaw:latest
```

Then deploy normally:

```bash
docker compose pull
docker compose up -d openclaw-gateway
```

## Troubleshooting

### Out of Memory During Build

**Symptom**: Build killed with exit code 137

**Solution**: Upgrade to e2-medium (4GB RAM) or build on a local machine with more RAM:

```bash
# Stop VM
gcloud compute instances stop tarvis-gateway --zone=us-central1-a

# Upgrade to e2-medium
gcloud compute instances set-machine-type tarvis-gateway \
  --machine-type=e2-medium \
  --zone=us-central1-a

# Start VM
gcloud compute instances start tarvis-gateway --zone=us-central1-a
```

After building, you can downgrade back to e2-small for runtime.

### Build Fails on pnpm install

**Symptom**: `pnpm install --frozen-lockfile` fails

**Solution**: 
1. Ensure you have the latest OpenClaw repository
2. Clear Docker build cache: `docker builder prune`
3. Try building with more memory

### Image Already Exists Error

**Symptom**: `image "docker.io/library/openclaw:latest": already exists`

**Solution**: This is a warning, not an error. The build succeeded. Remove old images:

```bash
docker image prune -f
```

## Build Process Fixes

### Issues Encountered During Initial Build

1. **gog Binary Download Failed**
   - **Issue**: Original guide included downloading `gog` binary from GitHub, but the URL pattern was incorrect
   - **Fix**: Removed from Dockerfile; can be installed separately if needed for Gmail integration
   - **Alternative**: Install `gog` manually in running container or use Gmail API directly

2. **Memory Requirements Underestimated**
   - **Issue**: e2-micro (1GB) and e2-small (2GB) both failed with OOM errors
   - **Fix**: Documented minimum requirement of e2-medium (4GB RAM) for building
   - **Recommendation**: Build on e2-medium, then downgrade to e2-small for runtime

3. **Docker Compose Build Configuration Missing**
   - **Issue**: Original `docker-compose.yml` referenced image but had no `build:` section
   - **Fix**: Added `build:` configuration with `context` and `dockerfile` parameters

## Cost Optimization

**Build Strategy:**
1. Use e2-medium (4GB RAM, ~$27/month) for building
2. Build takes ~10 minutes
3. Push image to Container Registry
4. Downgrade to e2-small (2GB RAM, ~$13/month) for runtime
5. Pull pre-built image on e2-small instance

**Cost Savings**: ~$14/month by not keeping e2-medium running 24/7

## Automated Build Pipeline (Optional)

For automated builds, consider using Cloud Build:

```bash
# Create cloudbuild.yaml
cat > cloudbuild.yaml << 'EOF'
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/openclaw:$COMMIT_SHA', '.']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['tag', 'gcr.io/$PROJECT_ID/openclaw:$COMMIT_SHA', 'gcr.io/$PROJECT_ID/openclaw:latest']
images:
  - 'gcr.io/$PROJECT_ID/openclaw:$COMMIT_SHA'
  - 'gcr.io/$PROJECT_ID/openclaw:latest'
EOF

# Submit build
gcloud builds submit --config cloudbuild.yaml .
```

## Next Steps

After building and pushing the image:
1. Update deployment `.env` to use registry image
2. Follow the [GCP Deployment Guide](gcp-deployment.md) to deploy
3. Configure integrations (Telegram, Gmail, Obsidian)

## Resources

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Google Container Registry Docs](https://cloud.google.com/container-registry/docs)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)

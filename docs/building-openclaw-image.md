# Building OpenClaw Docker Image

This guide covers building the OpenClaw Docker image **locally on your machine** and pushing it to Google Container Registry.

## Prerequisites

- **Docker installed locally** (Docker Desktop on Mac/Windows, Docker Engine on Linux)
- **`gcloud` CLI configured** with authentication
- **At least 4GB RAM** available on your local machine
- **Google Cloud project** with Container Registry enabled
- **20GB free disk space**

## Why Build From Source?

The pre-built image in the registry should work for most users. Build from source if you need to:
- Customize the Dockerfile
- Add additional binaries or dependencies
- Test unreleased OpenClaw features
- Contribute to OpenClaw development

## Build Environment Requirements

**Local Machine Requirements:**
- **RAM**: 4GB minimum (8GB recommended)
- **Disk**: 20GB free space
- **CPU**: 2+ cores recommended
- **OS**: macOS, Linux, or Windows with WSL2

**Why Build Locally?**
- No need to provision expensive cloud VMs for building
- Faster iteration during development
- Use your local machine's resources efficiently
- Only deploy the final image to cloud

## Step 1: Clone OpenClaw Repository

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

## Step 2: Create Dockerfile

Create `Dockerfile` with `gog` binary for Gmail integration:

```dockerfile
FROM node:22-bookworm

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# Install gog for Gmail integration
RUN curl -L https://github.com/steipete/gogcli/releases/download/v0.9.0/gogcli_0.9.0_linux_amd64.tar.gz \
  | tar -xz -C /usr/local/bin gog && chmod +x /usr/local/bin/gog

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

**Key Changes:**
- ✅ Added `gog` binary installation (v0.9.0) for Gmail integration
- ✅ Correct download URL: `gogcli_0.9.0_linux_amd64.tar.gz`
- ✅ Extract only the `gog` binary from the tarball

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

## Step 4: Build the Image Locally

```bash
# Build the image
docker compose build

# Or build directly with docker
docker build -t openclaw:latest .
```

**Build Time**: 5-10 minutes on a modern laptop

**Expected Output:**
- Base image pull: ~1-2 minutes (first time only)
- Package installation: ~2-3 minutes
- TypeScript compilation: ~2-3 minutes
- UI build: ~1 minute
- Image export: ~1-2 minutes

**Verify Build:**
```bash
# Check image size
docker images openclaw:latest

# Expected size: ~1.5GB
```

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
# Push both tags
docker push gcr.io/${PROJECT_ID}/openclaw:latest
docker push gcr.io/${PROJECT_ID}/openclaw:$(date +%Y%m%d)
```

**Push Time**: 3-5 minutes depending on your internet connection (image is ~1.5GB)

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

**Solution**: 
1. Close other applications to free up RAM
2. Increase Docker Desktop memory limit (Mac/Windows):
   - Docker Desktop → Settings → Resources → Memory → Set to 4GB+
3. On Linux, ensure you have at least 4GB free RAM:
   ```bash
   free -h
   ```

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

### gog Binary Not Found After Build

**Symptom**: `gog: command not found` when running in container

**Solution**: Verify the Dockerfile extracts only the `gog` binary:
```dockerfile
RUN curl -L https://github.com/steipete/gogcli/releases/download/v0.9.0/gogcli_0.9.0_linux_amd64.tar.gz \
  | tar -xz -C /usr/local/bin gog && chmod +x /usr/local/bin/gog
```

Test in running container:
```bash
docker compose exec openclaw-gateway gog --version
```

## Build Process Fixes

### Issues Encountered and Resolved

1. **gog Binary Download Failed**
   - **Issue**: Incorrect URL pattern and tarball extraction
   - **Fix**: Updated to correct URL `gogcli_0.9.0_linux_amd64.tar.gz` and extract only `gog` binary
   - **Working Command**: 
     ```bash
     curl -L https://github.com/steipete/gogcli/releases/download/v0.9.0/gogcli_0.9.0_linux_amd64.tar.gz | tar -xz -C /usr/local/bin gog
     ```

2. **Docker Compose Build Configuration Missing**
   - **Issue**: Original `docker-compose.yml` referenced image but had no `build:` section
   - **Fix**: Added `build:` configuration with `context` and `dockerfile` parameters

3. **Build Strategy Changed**
   - **Previous**: Build on cloud VM (requires e2-medium, $27/month)
   - **Current**: Build locally, push to registry, deploy on e2-small ($13/month)
   - **Savings**: ~$14/month + faster iteration

## Cost Optimization

**Recommended Build Strategy:**
1. ✅ Build locally on your machine (free, uses your existing hardware)
2. ✅ Push image to Container Registry (~$0.03/month for storage)
3. ✅ Deploy on e2-small (2GB RAM, ~$13/month) for runtime
4. ✅ Pull pre-built image on deployment

**Cost Savings**: 
- No need for expensive build VMs
- Total cloud cost: ~$13/month (just runtime VM)
- Build as often as needed without additional costs

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

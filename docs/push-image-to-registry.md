# Pushing OpenClaw Image to Container Registry

Quick reference for pushing the built Docker image to Google Container Registry.

## Current Status

✅ **Completed:**
- Docker image built successfully on VM: `openclaw:latest`
- Container Registry API enabled
- VM service account has storage.admin permissions

⚠️ **Pending:**
- Image needs to be pushed to `gcr.io/tarvis-assistant-1770716938/openclaw:latest`

## Option 1: Push from VM (Recommended)

SSH into your VM and run:

```bash
# SSH into VM
gcloud compute ssh tarvis-gateway --zone=us-central1-a

# Navigate to openclaw directory
cd openclaw

# Tag the image
docker tag openclaw:latest gcr.io/tarvis-assistant-1770716938/openclaw:latest
docker tag openclaw:latest gcr.io/tarvis-assistant-1770716938/openclaw:20260210

# Push to registry
docker push gcr.io/tarvis-assistant-1770716938/openclaw:latest
docker push gcr.io/tarvis-assistant-1770716938/openclaw:20260210
```

**If authentication fails**, the VM's default service account may need additional setup:

```bash
# On the VM, authenticate with your user account
gcloud auth login --no-launch-browser

# Follow the URL and paste the verification code

# Then retry the push
docker push gcr.io/tarvis-assistant-1770716938/openclaw:latest
```

## Option 2: Export and Push from Local Machine

If VM authentication continues to fail, export the image and push from your local machine:

```bash
# On VM: Save image to tar file
docker save openclaw:latest | gzip > openclaw-latest.tar.gz

# On VM: Check file size
ls -lh openclaw-latest.tar.gz

# Download to local machine
gcloud compute scp tarvis-gateway:~/openclaw/openclaw-latest.tar.gz . --zone=us-central1-a

# On local machine: Load image
docker load < openclaw-latest.tar.gz

# On local machine: Tag and push
docker tag openclaw:latest gcr.io/tarvis-assistant-1770716938/openclaw:latest
docker push gcr.io/tarvis-assistant-1770716938/openclaw:latest
```

## Verify Upload

```bash
# List images in registry
gcloud container images list --repository=gcr.io/tarvis-assistant-1770716938

# List tags for openclaw image
gcloud container images list-tags gcr.io/tarvis-assistant-1770716938/openclaw
```

## Update Deployment to Use Registry Image

Once pushed, update your VM's `.env` file:

```bash
# On VM
cd ~/tarvis
nano .env
```

Change:
```bash
OPENCLAW_IMAGE=openclaw:latest
```

To:
```bash
OPENCLAW_IMAGE=gcr.io/tarvis-assistant-1770716938/openclaw:latest
```

Then restart the container:

```bash
docker compose down
docker compose pull
docker compose up -d openclaw-gateway
```

## Troubleshooting

### Authentication Failed

**Symptom**: `error from registry: authentication failed`

**Solutions**:
1. Run `gcloud auth login --no-launch-browser` on the VM
2. Ensure VM service account has `roles/storage.admin`
3. Try pushing from local machine instead

### Permission Denied

**Symptom**: `denied: Permission "storage.objects.create" denied`

**Solution**: Grant storage admin role to VM service account:

```bash
gcloud projects add-iam-policy-binding tarvis-assistant-1770716938 \
  --member="serviceAccount:969335520721-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin"
```

### Image Too Large

**Symptom**: Push takes very long or times out

**Solution**: The image is ~1.5GB. Ensure good network connection. Consider using:
- Compression: Already enabled by default
- Parallel uploads: Docker handles this automatically
- Resume on failure: `docker push` will resume from last layer

## Next Steps

After successfully pushing the image:

1. ✅ Image is in Container Registry
2. ✅ Update deployment `.env` to use registry image
3. ✅ Pull image on VM: `docker compose pull`
4. ✅ Restart container: `docker compose up -d`
5. ⏳ Complete Telegram bot configuration
6. ⏳ Run onboarding wizard for AI provider setup
7. ⏳ Downgrade VM to e2-small for cost savings

## Cost Note

Container Registry storage costs:
- First 0.5GB: Free
- After 0.5GB: $0.026/GB/month

For a ~1.5GB image: ~$0.03/month (negligible)

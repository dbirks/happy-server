# Happy Server Deployment Guide

Modern deployment setup for happy-server using Docker Hardened Images and Helm.

## What We Built

### 🐳 Docker Setup
- **Base Images**: Official Alpine images - minimal and secure
  - `node:24-alpine` for Node.js runtime
  - Small footprint (~155MB vs 1GB+ for Debian)
  - Multi-stage build for optimal size
  - Runs as non-root user (UID 1001)

### ⚓ Helm Chart
- **Location**: `charts/happy-server/`
- **Dependencies**: Frozen Bitnami charts with Alpine image overrides (PostgreSQL/Redis)
  - PostgreSQL 17 (`postgres:17-alpine`)
  - Redis 7 (`redis:7-alpine`)
  - MinIO (S3-compatible object storage) - uses official Bitnami image
- **Features**:
  - Security contexts (runAsNonRoot, readOnlyRootFilesystem)
  - Resource limits and requests
  - Liveness/readiness/startup probes
  - PodDisruptionBudget for HA
  - Service exposes port 80 → container port 3005
  - Built-in S3-compatible storage via MinIO subchart

### 🚀 CI/CD Pipelines
- **Release Please**: Automated versioning via conventional commits
- **Docker Build**: Multi-platform (amd64/arm64) images to GHCR
- **Helm Release**: OCI charts published to GHCR

## Prerequisites

### GitHub Repository Setup
The workflows use `GITHUB_TOKEN` (automatically provided) for GHCR publishing. No additional authentication needed since we're using public Alpine images.

## Local Development

### Install Dependencies
```bash
cd ~/dev/happy-server
helm dependency update charts/happy-server
```

### Test the Chart
```bash
# Lint
helm lint charts/happy-server/

# Dry run
helm install happy-server charts/happy-server/ --dry-run --debug

# Template
helm template happy-server charts/happy-server/
```

### Build Docker Image Locally
```bash
# Build (no authentication needed)
docker build -t happy-server:local .

# Test run
docker run -p 3005:3005 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  -e REDIS_URL=redis://host:6379 \
  happy-server:local
```

## Deployment to Kubernetes

### Using Flux (like your home-k8s)

**1. Create HelmRepository for your fork:**
```yaml
# prereqs/helm-repos/happy-server.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: happy-server
  namespace: flux-system
spec:
  type: oci
  url: oci://ghcr.io/dbirks/charts
  interval: 5m
```

**2. Create HelmRelease:**
```yaml
# apps/happy-server.yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: happy-server
  namespace: default
spec:
  interval: 5m
  chart:
    spec:
      chart: happy-server
      version: 0.1.0  # Or use semver range: ">=0.1.0 <1.0.0"
      sourceRef:
        kind: HelmRepository
        name: happy-server
        namespace: flux-system
  values:
    image:
      repository: ghcr.io/dbirks/happy-server
      tag: "0.1.0"

    replicaCount: 2

    # Use bundled PostgreSQL and Redis with Alpine images
    postgresql:
      enabled: true
      image:
        registry: docker.io
        repository: postgres
        tag: "17-alpine"
      auth:
        database: happy_server
        username: happy_server

    redis:
      enabled: true
      image:
        registry: docker.io
        repository: redis
        tag: "7-alpine"

    # Or use external databases
    # postgresql:
    #   enabled: false
    # redis:
    #   enabled: false
    # envFrom:
    #   - secretRef:
    #       name: happy-server-external-db
```

**3. Create required secrets:**
```bash
# MinIO is enabled by default, so you only need HANDY_MASTER_SECRET
MASTER_SECRET=$(openssl rand -base64 32)

kubectl create secret generic happy-server-secrets \
  --from-literal=HANDY_MASTER_SECRET="$MASTER_SECRET" \
  -n default

# Or if using external S3 instead (set minio.enabled=false):
kubectl create secret generic happy-server-secrets \
  --from-literal=HANDY_MASTER_SECRET="$MASTER_SECRET" \
  --from-literal=S3_HOST=s3.amazonaws.com \
  --from-literal=S3_PORT=443 \
  --from-literal=S3_USE_SSL=true \
  --from-literal=S3_ACCESS_KEY=your-access-key \
  --from-literal=S3_SECRET_KEY=your-secret-key \
  --from-literal=S3_BUCKET=happy-server-uploads \
  --from-literal=S3_PUBLIC_URL=https://s3.amazonaws.com/happy-server-uploads \
  -n default
```

### Using Helm Directly
```bash
# Install from GHCR (after first release)
helm install happy-server oci://ghcr.io/dbirks/charts/happy-server --version 0.1.0

# Or install from local chart
helm install happy-server ./charts/happy-server \
  --set postgresql.enabled=true \
  --set redis.enabled=true
```

## Release Process

This repository uses **independent versioning** for the application and Helm chart. Each component can be released separately using conventional commits.

### Initial Beta Releases
Both packages start in prerelease mode (beta). To publish the first stable releases, remove `prerelease: true` and `prerelease-type: "beta"` from `.release-please-config.json`.

### 1. Make Changes Using Conventional Commits

**For application changes:**
```bash
git commit -m "feat: add new API endpoint"
git commit -m "fix: resolve database connection issue"
git push origin main
```

**For Helm chart changes:**
```bash
cd charts/happy-server
# Edit values.yaml, templates, etc.
git commit -m "feat(chart): add resource limits configuration"
git commit -m "fix(chart): correct service port mapping"
git push origin main
```

### 2. Release Please Creates Separate PRs
- **Application PR**: Updates package.json, creates `v0.1.0-beta.1` tag
- **Chart PR**: Updates Chart.yaml, creates `happy-server-chart-v0.1.0-beta.1` tag
- Each PR has its own changelog based on relevant commits

### 3. Merge Release PRs
- Merge application PR → triggers `docker-build.yml` (tag: `v*`)
- Merge chart PR → triggers `helm-release.yml` (tag: `happy-server-chart-v*`)

### 4. Automated Publishing
**Application release:**
- Docker image built for amd64 + arm64
- Pushed to `ghcr.io/dbirks/happy-server:0.1.0-beta.1`

**Chart release:**
- Helm chart packaged and pushed to `ghcr.io/dbirks/charts/happy-server:0.1.0-beta.1`

### 5. Independent Version Evolution
- Application and chart versions evolve independently
- Update chart configuration without releasing new app version
- Release new app versions without changing chart
- Both follow semantic versioning with conventional commits

### 6. Flux Auto-Updates (Optional)
Configure Flux ImageUpdateAutomation to auto-update your HelmRelease when new images are published.

## Using Alpine Images

Official Alpine images are publicly available and require no authentication. They're smaller and simpler than Debian-based images, making them ideal for containerized deployments.

## Chart Configuration

### Key Values to Customize

```yaml
# Replicas
replicaCount: 2

# Image
image:
  repository: ghcr.io/dbirks/happy-server
  tag: ""  # Defaults to chart appVersion

# Resources
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi

# Database (bundled)
postgresql:
  enabled: true
  auth:
    database: happy_server
    username: happy_server
  primary:
    persistence:
      size: 10Gi

# Redis (bundled)
redis:
  enabled: true
  master:
    persistence:
      size: 1Gi

# MinIO (bundled S3-compatible storage)
minio:
  enabled: true
  auth:
    rootUser: admin
    rootPassword: minio123  # Change for production!
  persistence:
    size: 10Gi
  defaultBuckets: "happy"
```

## Troubleshooting

### Chart Dependency Issues
```bash
cd charts/happy-server
helm dependency update
```

### Postgres/Redis Not Starting
Check if images are being pulled correctly:
```bash
kubectl describe pod <pod-name> -n default
# Look for ImagePullBackOff errors
```

Alpine images are public, so authentication shouldn't be an issue. If you see pull errors, check your internet connectivity or Docker Hub rate limits.

## Next Steps

1. **First Releases**:
   - Push conventional commits for app and/or chart
   - Release-please creates separate PRs for each component
   - Merge PRs to publish beta versions
2. **Test Deployment**: Deploy to your k8s cluster via Flux
3. **Monitor**: Check pods, logs, and service health
4. **Iterate**: Make improvements to app or chart independently
5. **Go Stable**: Remove prerelease flags from config when ready for 0.1.0

## Architecture Decisions

### Independent Versioning for App and Chart
- Application and Helm chart have separate version numbers
- Allows chart improvements (config, security, resources) without app changes
- App can release new features without requiring chart updates
- Both use semantic versioning via conventional commits
- Prerelease mode (beta) for initial development, stable releases later

### Why Bitnami Charts with Alpine Images?
- Bitnami charts are frozen but still work (Apache 2.0 source)
- Alpine images are drop-in replacements (free, small, no auth needed)
- Avoids complexity of operators for self-hosted use case
- Can migrate to operators or DHI later if needed

### Why Not Operators?
- CloudNativePG and OpsTree Redis are excellent for production at scale
- For self-hosted happy-server, subchart simplicity wins
- Can always migrate later

### Port Configuration
- Container runs on **3005** (happy-server default)
- Service exposes **port 80** in cluster (standard HTTP)
- `http://happy-server.default.svc.cluster.local:80` → `container:3005`

## Resources

- [Official Node.js Alpine Images](https://hub.docker.com/_/node)
- [Official PostgreSQL Alpine Images](https://hub.docker.com/_/postgres)
- [Official Redis Alpine Images](https://hub.docker.com/_/redis)
- [Release Please](https://github.com/googleapis/release-please)
- [Helm OCI Support](https://helm.sh/docs/topics/registries/)
- [Flux HelmRelease](https://fluxcd.io/flux/components/helm/helmreleases/)

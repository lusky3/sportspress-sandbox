# GitHub Configuration

## workflows/build-image.yml

GitHub Actions workflow that:

- Builds Docker image on push/PR
- Pushes to GitHub Container Registry
- Tags with branch/commit SHA
- Uses `Dockerfile` as build context

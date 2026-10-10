# Docker Image Analysis

## 1. Image Size

The final image, `secure-node-app:1.0`, is approximately **166 MB**.

I used a pinned Node.js Alpine image, a multi-stage build, and production dependencies only. I also added a `.dockerignore` file to exclude unnecessary files.

For comparison, a generic `node:latest` image could be around 1.2 GB, depending on the version and platform. Using that as an estimate, my image is about 86% smaller. I did not build a separate image to measure this comparison directly.

## 2. Multi-Stage Build

I used separate build and runtime stages. The build stage installs the application dependencies, while the runtime stage contains only the files needed to run the application.

This reduces unnecessary files and tools in the final image, helping to reduce its attack surface.

## 3. Running as a Non-Root User

The application runs as a dedicated user with UID 1001 instead of root. This limits the privileges available to the application if it is compromised.

I verified this by running `docker exec secure-node-container id`, which confirmed UID 1001.

## 4. Vulnerability Scanning

I used Trivy to scan the image:

`trivy image --severity HIGH,CRITICAL --exit-code 1 secure-node-app:1.0`

The first scan reported 11 HIGH vulnerabilities in packages bundled with npm. I removed npm, Corepack and Yarn from the runtime image because they were not needed to run the application.

After rebuilding and scanning again, Trivy reported zero HIGH or CRITICAL findings in the scanned operating system packages and application dependencies. The previous npm-related findings were no longer detected.

## 5. Handling Unfixable Vulnerabilities

If a base image vulnerability has no available fix, I would:

- Check the vulnerability details and confirm whether the affected package is relevant to the application.
- Look for an updated or alternative base image.
- Assess the risk and apply suitable mitigations.
- Document the issue and obtain the required security approval.
- Monitor for a fix and rescan the image when an update becomes available.

## 6. Other Security Measures

The Dockerfile and project include the following measures:

- Pinned Node.js Alpine image tag instead of `latest`.
- Production-only dependencies installed with `npm ci --omit=dev`.
- A non-root user with UID 1001.
- A health check using the `/health` endpoint.
- Resource-conscious Node.js configuration.
- A `.dockerignore` file to exclude unnecessary files and environment secrets from the build context.

## 7. Testing and Conclusion

I rebuilt the image and confirmed that the application and health endpoint worked correctly. I also verified that the container runs as a non-root user.

The final image is approximately 166 MB, and the final Trivy scan reported no HIGH or CRITICAL findings in the scanned components. Regular updates and vulnerability scans are still needed to keep the image secure.
# Tool Functions for the MDENet Education Platform

This repository contains the backend tool functions for the MDENet education platform.

See the readme file in the respective tool directory for instructions on running a particular tool 

[Conversion](services/com.mde-network.ep.toolfunctions.epsilonfunction/README.md)

[Eclipse OCL](services/com.mde-network.ep.toolfunctions.eclipseoclfunction/README.md)

[Emfatic](services/com.mde-network.ep.toolfunctions.emfaticfunction/README.md)

[Epsilon ](https://github.com/epsilonlabs/playground-micronaut/)

[Xtext (MDENet)](services/com.mde-network.ep.toolfunctions.xtextfunction/README.md)

## Building Tool Docker Images

All tool services are built from a single root-level `Dockerfile` using Docker's multi-stage build. A shared Maven build stage compiles all tool modules once; subsequent stages copy only the artifacts required for each individual tool.

**The build context must be the repository root.**

To build a specific tool service image, target the appropriate stage:

```bash
# EMF tool
docker build --target toolservice-emf -t emf-tool .

# Emfatic tool
docker build --target toolservice-emfatic -t emfatic-tool .

# Eclipse OCL tool
docker build --target toolservice-ocl -t ocl-tool .

# Conversion (Epsilon) tool
docker build --target toolservice-conversion -t conversion-tool .

# Xtext tool
docker build --target toolservice-xtext -t xtext-tool .
```

The Xtext stage accepts optional build arguments for CORS and editor server configuration:

```bash
docker build --target toolservice-xtext \
  --build-arg TRUSTED_ORIGINS="https://example.com" \
  --build-arg ES_ADDRESS="http://localhost:10001" \
  --build-arg ES_DEPLOY_ADDRESS="http://localhost:8080" \
  -t xtext-tool .
```





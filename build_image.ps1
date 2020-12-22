$env:DOCKER_CONTENT_TRUST=1
$env:DOCKER_CONTENT_TRUST_SERVER="https://dev.hszofficial.site:4443"
docker buildx build --load --platform=linux/arm/v6 -t dev.hszofficial.site:9443/test/hellodocker:armv6-0.0.0 -t dev.hszofficial.site:9443/test/hellodocker:armv6-latest .
docker buildx build --load --platform=linux/arm/v7 -t dev.hszofficial.site:9443/test/hellodocker:armv7-0.0.0 -t dev.hszofficial.site:9443/test/hellodocker:armv7-latest .
docker buildx build --load --platform=linux/arm64 -t dev.hszofficial.site:9443/test/hellodocker:arm64-0.0.0 -t dev.hszofficial.site:9443/test/hellodocker:arm64-latest .
docker buildx build --load --platform=linux/amd64 -t dev.hszofficial.site:9443/test/hellodocker:amd64-0.0.0 -t dev.hszofficial.site:9443/test/hellodocker:amd64-latest .

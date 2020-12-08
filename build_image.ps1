docker buildx build --load --platform=linux/arm/v6 -t hsz1273327/hellodocker:armv6-0.0.0 -t hsz1273327/hellodocker:armv6-latest .
docker buildx build --load --platform=linux/arm/v7 -t hsz1273327/hellodocker:armv7-0.0.0 -t hsz1273327/hellodocker:armv7-latest .
docker buildx build --load --platform=linux/arm64 -t hsz1273327/hellodocker:arm64-0.0.0 -t hsz1273327/hellodocker:arm64-latest .
docker buildx build --load --platform=linux/amd64 -t hsz1273327/hellodocker:amd64-0.0.0 -t hsz1273327/hellodocker:amd64-latest .

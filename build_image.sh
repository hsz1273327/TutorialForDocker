docker buildx build --load --platform=linux/arm/v6 -t hsz1273327/hellodocker-go:armv6-0.0.0 -t hsz1273327/hellodocker-go:armv6-latest .
docker buildx build --load --platform=linux/arm/v7 -t hsz1273327/hellodocker-go:armv7-0.0.0 -t hsz1273327/hellodocker-go:armv7-latest .
docker buildx build --load --platform=linux/arm64 -t hsz1273327/hellodocker-go:arm64-0.0.0 -t hsz1273327/hellodocker-go:arm64-latest .
docker buildx build --load --platform=linux/amd64 -t hsz1273327/hellodocker-go:amd64-0.0.0 -t hsz1273327/hellodocker-go:amd64-latest .
docker buildx build --platform=linux/arm/v6 -t hsz1273327/test_sanic:armv6-0.0.0 -t hsz1273327/test_sanic:armv6-latest .
docker buildx build --platform=linux/arm/v7 -t hsz1273327/test_sanic:armv7-0.0.0 -t hsz1273327/test_sanic:armv7-latest .
docker buildx build --platform=linux/arm64 -t hsz1273327/test_sanic:arm64-0.0.0 -t hsz1273327/test_sanic:arm64-latest .
docker buildx build --platform=linux/amd64 -t hsz1273327/test_sanic:amd64-0.0.0 -t hsz1273327/test_sanic:amd64-latest .
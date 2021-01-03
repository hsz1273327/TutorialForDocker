
docker buildx build --load --platform=linux/arm/v6 -t dev.hszofficial.site:9443/stock/hello-docker:armv6-0.0.0 -t dev.hszofficial.site:9443/stock/hello-docker:armv6-latest .
docker buildx build --load --platform=linux/arm/v7 -t dev.hszofficial.site:9443/stock/hello-docker:armv7-0.0.0 -t dev.hszofficial.site:9443/stock/hello-docker:armv7-latest .
docker buildx build --load --platform=linux/arm64 -t dev.hszofficial.site:9443/stock/hello-docker:arm64-0.0.0 -t dev.hszofficial.site:9443/stock/hello-docker:arm64-latest .
docker buildx build --load --platform=linux/amd64 -t dev.hszofficial.site:9443/stock/hello-docker:amd64-0.0.0 -t dev.hszofficial.site:9443/stock/hello-docker:amd64-latest .

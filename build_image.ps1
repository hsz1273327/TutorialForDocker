
docker buildx build --load --platform=linux/arm/v6 -t dev.hszofficial.site:9443/stock/hellodocker:armv6-0.0.0 -t dev.hszofficial.site:9443/stock/hellodocker:armv6-latest .
docker buildx build --load --platform=linux/arm/v7 -t dev.hszofficial.site:9443/stock/hellodocker:armv7-0.0.0 -t dev.hszofficial.site:9443/stock/hellodocker:armv7-latest .
docker buildx build --load --platform=linux/arm64 -t dev.hszofficial.site:9443/stock/hellodocker:arm64-0.0.0 -t dev.hszofficial.site:9443/stock/hellodocker:arm64-latest .
docker buildx build --load --platform=linux/amd64 -t dev.hszofficial.site:9443/stock/hellodocker:amd64-0.0.0 -t dev.hszofficial.site:9443/stock/hellodocker:amd64-latest .

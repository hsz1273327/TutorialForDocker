docker buildx build --load --platform=linux/arm/v7 -t hsz1273327/iperf3:armv7-3.7 -t hsz1273327/iperf3:armv7-latest .
docker buildx build --load --platform=linux/arm64 -t hsz1273327/iperf3:arm64-3.7 -t hsz1273327/iperf3:arm64-latest .
docker buildx build --load --platform=linux/amd64 -t hsz1273327/iperf3:amd64-3.7 -t hsz1273327/iperf3:amd64-latest .
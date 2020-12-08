docker push hsz1273327/hellodocker
docker manifest create hsz1273327/hellodocker:0.0.0 hsz1273327/hellodocker:armv6-0.0.0 hsz1273327/hellodocker:armv7-0.0.0 hsz1273327/hellodocker:arm64-0.0.0 hsz1273327/hellodocker:amd64-0.0.0
docker manifest create hsz1273327/hellodocker:latest hsz1273327/hellodocker:armv6-latest hsz1273327/hellodocker:armv7-latest hsz1273327/hellodocker:arm64-latest hsz1273327/hellodocker:amd64-latest

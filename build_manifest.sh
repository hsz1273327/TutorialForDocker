docker push -a hsz1273327/hellodocker-go
docker manifest create hsz1273327/hellodocker-go:0.0.0 hsz1273327/hellodocker-go:armv6-0.0.0 hsz1273327/hellodocker-go:armv7-0.0.0 hsz1273327/hellodocker-go:arm64-0.0.0 hsz1273327/hellodocker-go:amd64-0.0.0
docker manifest create hsz1273327/hellodocker-go:latest hsz1273327/hellodocker-go:armv6-latest hsz1273327/hellodocker-go:armv7-latest hsz1273327/hellodocker-go:arm64-latest hsz1273327/hellodocker-go:amd64-latest

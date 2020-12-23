docker push -a hsz1273327/iperf3
docker manifest create hsz1273327/iperf3:3.7 hsz1273327/iperf3:armv7-3.7 hsz1273327/iperf3:arm64-3.7 hsz1273327/iperf3:amd64-3.7
docker manifest create hsz1273327/iperf3:latest hsz1273327/iperf3:armv7-latest hsz1273327/iperf3:arm64-latest hsz1273327/iperf3:amd64-latest

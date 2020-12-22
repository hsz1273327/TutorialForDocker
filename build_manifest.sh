export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER="https://dev.hszofficial.site:4443"
docker push dev.hszofficial.site:9443/test/hellodocker:armv6-0.0.0
docker push dev.hszofficial.site:9443/test/hellodocker:armv7-0.0.0
docker push dev.hszofficial.site:9443/test/hellodocker:arm64-0.0.0
docker push dev.hszofficial.site:9443/test/hellodocker:amd64-0.0.0
docker push dev.hszofficial.site:9443/test/hellodocker:armv6-latest
docker push dev.hszofficial.site:9443/test/hellodocker:armv7-latest
docker push dev.hszofficial.site:9443/test/hellodocker:arm64-latest
docker push dev.hszofficial.site:9443/test/hellodocker:amd64-latest

docker manifest create dev.hszofficial.site:9443/test/hellodocker:0.0.0 dev.hszofficial.site:9443/test/hellodocker:armv6-0.0.0 dev.hszofficial.site:9443/test/hellodocker:armv7-0.0.0 dev.hszofficial.site:9443/test/hellodocker:arm64-0.0.0 dev.hszofficial.site:9443/test/hellodocker:amd64-0.0.0
docker manifest create dev.hszofficial.site:9443/test/hellodocker:latest dev.hszofficial.site:9443/test/hellodocker:armv6-latest dev.hszofficial.site:9443/test/hellodocker:armv7-latest dev.hszofficial.site:9443/test/hellodocker:arm64-latest dev.hszofficial.site:9443/test/hellodocker:amd64-latest

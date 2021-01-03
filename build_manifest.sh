export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER="https://dev.hszofficial.site:4443"

docker push dev.hszofficial.site:9443/test/hello-docker:armv6-0.0.0
docker push dev.hszofficial.site:9443/test/hello-docker:armv7-0.0.0
docker push dev.hszofficial.site:9443/test/hello-docker:arm64-0.0.0
docker push dev.hszofficial.site:9443/test/hello-docker:amd64-0.0.0
docker push dev.hszofficial.site:9443/test/hello-docker:armv6-latest
docker push dev.hszofficial.site:9443/test/hello-docker:armv7-latest
docker push dev.hszofficial.site:9443/test/hello-docker:arm64-latest
docker push dev.hszofficial.site:9443/test/hello-docker:amd64-latest

docker manifest create dev.hszofficial.site:9443/test/hello-docker:0.0.0 dev.hszofficial.site:9443/test/hello-docker:armv6-0.0.0 dev.hszofficial.site:9443/test/hello-docker:armv7-0.0.0 dev.hszofficial.site:9443/test/hello-docker:arm64-0.0.0 dev.hszofficial.site:9443/test/hello-docker:amd64-0.0.0
docker manifest create dev.hszofficial.site:9443/test/hello-docker:latest dev.hszofficial.site:9443/test/hello-docker:armv6-latest dev.hszofficial.site:9443/test/hello-docker:armv7-latest dev.hszofficial.site:9443/test/hello-docker:arm64-latest dev.hszofficial.site:9443/test/hello-docker:amd64-latest

docker push -a hsz1273327/standalone_colume_nfs
docker manifest create hsz1273327/standalone_colume_nfs:0.0.1 hsz1273327/standalone_colume_nfs:armv7-0.0.1 hsz1273327/standalone_colume_nfs:arm64-0.0.1 hsz1273327/standalone_colume_nfs:amd64-0.0.1
docker manifest create hsz1273327/standalone_colume_nfs:latest hsz1273327/standalone_colume_nfs:armv7-latest hsz1273327/standalone_colume_nfs:arm64-latest hsz1273327/standalone_colume_nfs:amd64-latest

FROM --platform=$TARGETPLATFORM alpine:3.12.2
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk update && apk --no-cache add apache2-utils && rm -rf /var/cache/apk/* 
ENTRYPOINT [ "ab" ]

FROM --platform=${TARGETPLATFORM} debian:buster-slim
CMD [ "ls", "/dev" ]
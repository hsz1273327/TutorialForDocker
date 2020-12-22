FROM --platform=$TARGETPLATFORM python:3.8.6-alpine as build
ADD pip.conf /etc/pip.conf
RUN pip install --upgrade pip
WORKDIR /code
RUN mkdir /code/app
ADD requirements_flask.txt /code/requirements.txt
RUN python -m pip install -r requirements.txt --target app
RUN rm -rf app/*.dist-info
ADD appflask/__main__.py /code/app/__main__.py
RUN python -m zipapp -p "/usr/bin/env python3" app

FROM python:3.8.6-alpine as app
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk update && apk --no-cache add curl && rm -rf /var/cache/apk/*
WORKDIR /code
COPY --from=build /code/app.pyz /code
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl","-f","http://localhost:5000/ping" ]
CMD [ "python" ,"app.pyz"]
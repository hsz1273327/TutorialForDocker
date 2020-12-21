FROM --platform=$TARGETPLATFORM python:3.8.6-slim-buster as build_bin
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt update -y && apt install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
ADD pip.conf /etc/pip.conf
RUN pip --no-cache-dir install --upgrade pip
WORKDIR /code
RUN mkdir /code/app
ADD requirements.txt /code/requirements.txt
RUN python -m pip --no-cache-dir install -r requirements.txt --target app
RUN rm -rf app/*.dist-info

FROM --platform=$TARGETPLATFORM python:3.8.6-slim-buster as build_img
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt update -y && apt install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
COPY --from=build_bin /code/app /code/app/
ADD app/__main__.py /code/app/__main__.py
RUN ls /code/app
WORKDIR /code
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl","-f","http://localhost:5000/ping" ]
CMD ["python" ,"app"]


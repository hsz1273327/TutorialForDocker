FROM --platform=$TARGETPLATFORM python:3.8.6-slim-buster as build
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt update -y && apt install -y --no-install-recommends build-essential curl && rm -rf /var/lib/apt/lists/*
ADD pip.conf /etc/pip.conf
RUN pip --no-cache-dir install --upgrade pip
WORKDIR /code
RUN mkdir /code/app
ADD requirements.txt /code/requirements.txt
RUN python -m pip --no-cache-dir install -r requirements.txt --target app
RUN rm -rf app/*.dist-info
ADD app/__main__.py /code/app/__main__.py
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl","-f","http://localhost:5000/ping" ]
CMD ["python" ,"app"]


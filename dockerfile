FROM --platform=$TARGETPLATFORM python:3.9-alpine
#COPY pip.conf /etc/pip.conf
RUN pip --no-cache-dir install --upgrade pip
WORKDIR /code
COPY requirements.txt /code/requirements.txt
RUN python -m pip --no-cache-dir install -r requirements.txt
RUN rm -rf TutorialForDocker/*.dist-info
# 复制源文件
COPY app.py /code/app.py
CMD ["python" ,"app.py"]

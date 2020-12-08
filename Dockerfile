FROM python:3.8
ADD requirements.txt /code/requirements.txt
ADD pip.conf /etc/pip.conf
WORKDIR /code
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
ADD app.py /code/app.py
CMD [ "python" ,"app.py"]

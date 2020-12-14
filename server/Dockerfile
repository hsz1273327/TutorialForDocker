FROM python:3.8
ADD requirements.txt /code/requirements.txt
ADD wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -o /code/wait-for-it.sh
ADD pip.conf /etc/pip.conf
WORKDIR /code
RUN chmod +x wait-for-it.sh
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
ADD app.py /code/app.py
ENV HOST 4000
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl","-f","http://localhost:4000/ping" ]
CMD [ "python" ,"app.py"]
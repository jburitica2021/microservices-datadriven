FROM python:3.6.13-alpine3.13
ENV LD_LIBRARY_PATH=/lib/instantclient_19_3
RUN wget -q -O - https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-basic-linux.x64-19.3.0.0.0dbru.zip | unzip -d /lib - && \
    apk add libaio
WORKDIR /app
COPY /inventory/requirements.txt .
RUN python3.6 -m pip install -r requirements.txt
ADD inventory .
ADD common .
CMD ["gunicorn", "app:app", "--config=config.py"]

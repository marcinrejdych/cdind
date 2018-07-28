FROM openjdk:8-jdk-alpine3.8

RUN apk --update --no-cache \
    add bash docker jq ca-certificates xz \
    curl device-mapper gcc python2 python2-dev py-pip build-base iptables bash gawk sed grep bc coreutils git && \
    rm -rf /var/cache/apk/*


COPY docker-utils.sh /docker-utils.sh

COPY requirements.txt /requirements.txt

RUN pip install --upgrade pip && pip install -r requirements.txt && rm -r /root/.cache

ENTRYPOINT [ "/bin/docker", "daemon" ]
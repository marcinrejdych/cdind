FROM openjdk:8u151-jdk-alpine3.7

ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 18.03.0-ce

RUN apk --update --no-cache --progress \
    add curl device-mapper gcc python2 python2-dev py-pip build-base iptables bash gawk sed grep bc coreutils && \
    rm -rf /var/cache/apk/*

RUN curl https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
    mv /docker/* /bin/ && chmod +x /bin/docker*

COPY docker-utils.sh /docker-utils.sh

COPY requirements.txt /requirements.txt

RUN pip install --upgrade pip && pip install -r requirements.txt && rm -r /root/.cache

ENTRYPOINT [ "/bin/docker", "daemon" ]
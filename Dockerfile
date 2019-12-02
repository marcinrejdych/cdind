FROM alpine:3.10

RUN apk --update --no-cache \
    add bash less docker jq openssh ca-certificates xz nss \
    openjdk11 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    curl device-mapper gcc python2 python2-dev py-pip build-base iptables bash gawk sed grep bc coreutils git && \
    rm -rf /var/cache/apk/*

COPY docker-utils.sh /docker-utils.sh

RUN pip install --upgrade pip && pip install virtualenv && rm -r /root/.cache

ENTRYPOINT [ "/bin/docker", "daemon" ]

FROM alpine:3.9

RUN apk --update --no-cache \
    add bash less docker jq openssh ca-certificates xz \
    openjdk8 \
    curl device-mapper gcc python2 python2-dev py-pip build-base iptables bash gawk sed grep bc coreutils git && \
    rm -rf /var/cache/apk/*


COPY docker-utils.sh /docker-utils.sh

COPY requirements.txt /requirements.txt

RUN pip install --upgrade pip && pip install -r requirements.txt && rm -r /root/.cache

ENTRYPOINT [ "/bin/docker", "daemon" ]

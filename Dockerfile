FROM alpine:latest

RUN apk update \
    && apk add tar dpkg xz \
    && find /var/lib/apk -type f -delete

COPY /assets/extract.sh /extract.sh
RUN chmod +x /extract.sh
ENTRYPOINT ["/extract.sh"]

ARG WORKDIR=/workdir
ENV WORKDIR=$WORKDIR
VOLUME $WORKDIR
WORKDIR $WORKDIR

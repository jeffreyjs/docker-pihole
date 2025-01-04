FROM alpine:3.20.2

ARG CFSSL_VERSION=latest

RUN apk update --no-cache ; \
    apk add --no-cache \
    curl gcc git go \
    libc-dev libgcc libltdl libtool ; \
    export GOPATH=/go ; \
    mkdir /go ; \
    go install github.com/cloudflare/cfssl/cmd/...@${CFSSL_VERSION} ; \
    apk del \
    gcc git go \
    libc-dev libgcc libtool ; \
    mkdir /etc/cfssl ; \
    mv /go/bin/* /bin ; \
    rm /var/cache/apk/* ; \
    rm -rf /go

VOLUME /etc/cfssl
WORKDIR /etc/cfssl
EXPOSE 8888
ENTRYPOINT [ "/bin/cfssl" ]

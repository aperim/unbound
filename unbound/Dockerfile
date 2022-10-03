# ----------------------------

FROM alpine:3.16.2 as unbound
ARG UNBOUND_VERSION=latest

WORKDIR /tmp/src

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN addgroup _unbound && adduser -D -H -s /etc -h /dev/null -G _unbound _unbound

RUN apk add --no-cache build-base=0.5-r3 curl=7.83.1-r3 linux-headers=5.16.7-r1 libevent=2.1.12-r4 libevent-dev=2.1.12-r4 expat=2.4.9-r0 expat-dev=2.4.9-r0 openssl=1.1.1q-r0 openssl-dev=1.1.1q-r0 nghttp2-dev=1.47.0-r0 && \
      curl -L https://github.com/lukas2511/dehydrated/archive/master.tar.gz | tar -xz && \
      mkdir -p /opt && \
      mv ./dehydrated-master/dehydrated /opt/ && \
      curl -fsSL https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz -o unbound.tar.gz && \
      curl -fsSL https://www.internic.net/domain/named.root -o root.hints && \
      tar xzf unbound.tar.gz && \
      cd unbound-* && \
      ./configure --prefix=/opt/unbound --with-pthreads --with-username=_unbound --with-libevent --with-libnghttp2 --enable-event-api --disable-flto && \
      make && make install && \
      cd .. && \
      mkdir -p /opt/unbound/etc/unbound/var && \
      mv root.hints /opt/unbound/etc/unbound/var/ && \
      rm -Rf /opt/unbound/share /opt/unbound/include /opt/unbound/etc/unbound/unbound.conf

# ----------------------------

FROM alpine:3.16.2

ARG BUILD_DESCRIPTION="Unbound, in a container"
ARG UNBOUND_VERSION=latest
ARG BUILD_NAME="Unbound v${UNBOUND_VERSION}"
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

LABEL \
    maintainer="Troy Kelly <troy@troykelly.com>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Troy Kelly" \
    org.opencontainers.image.authors="Troy Kelly <troy@troykelly.com>" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.url="https://troykelly" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

COPY --from=unbound /opt/ /opt/

COPY start.sh pi-hole.conf unbound.conf /

WORKDIR /opt/unbound/etc/unbound

RUN apk add --no-cache \
      bash=5.1.16-r2 \
      coreutils=9.1-r0 \
      curl=7.83.1-r3 \
      diffutils=3.8-r0 \
      drill=1.8.1-r0 \
      expat=2.4.9-r0 \
      gawk=5.1.1-r0 \
      grep=3.7-r0 \
      libevent=2.1.12-r4 \
      openssl=1.1.1q-r0 \
      sed=4.8-r0 && \
      addgroup _unbound && adduser -D -H -s /etc -h /dev/null -G _unbound _unbound && \
      chmod +x /start.sh && \
      chmod -x /unbound.conf /pi-hole.conf && \
      mkdir -p unbound.conf.d && \
      cp -av /unbound.conf . && \
      cp -av /pi-hole.conf unbound.conf.d/ && \
      chown -R _unbound:_unbound /opt/unbound /unbound.conf /pi-hole.conf

ENV PATH /opt/unbound/sbin:"$PATH"

EXPOSE 5353/tcp 5353/udp

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD drill -p 5353 @127.0.0.1 google.com || exit 1

CMD ["/start.sh"]
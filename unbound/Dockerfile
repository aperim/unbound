# ----------------------------

FROM alpine as unbound
ARG UNBOUND_VERSION=latest

WORKDIR /tmp/src

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN addgroup _unbound && adduser -D -H -s /etc -h /dev/null -G _unbound _unbound

RUN apk add --no-cache build-base curl linux-headers libevent libevent-dev expat expat-dev openssl openssl-dev nghttp2-dev && \
      curl -L https://github.com/lukas2511/dehydrated/archive/master.tar.gz | tar -xz && \
      mkdir -p /opt && \
      mv ./dehydrated-master/dehydrated /opt/ && \
      curl -fsSL https://nlnetlabs.nl/downloads/unbound/unbound-${VERSION}.tar.gz -o unbound.tar.gz && \
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

FROM alpine

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
      bash \
      coreutils \
      curl \
      diffutils \
      drill \
      expat \
      gawk \
      grep \
      libevent \
      openssl \
      sed && \
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
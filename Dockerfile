# ----------------------------

FROM alpine as unbound
ARG VERSION=latest

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

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

LABEL maintainer="Troy Kelly <troy@aperim.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="aperim/unbound"
LABEL org.label-schema.description="Unbound v{$VERSION} recursive DNS resolver for PiHole"
LABEL org.label-schema.url="https://unbound.net/"
LABEL org.label-schema.vcs-url="https://github.com/aperim/unbound"
LABEL org.label-schema.docker.cmd="docker run -p 5353:5353/tcp -p 5353:5353/udp aperim/unbound"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.version="${VERSION}"
LABEL org.label-schema.vcs-ref="${VCS_REF}"

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
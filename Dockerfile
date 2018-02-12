# qBittorrent and OpenVPN
#
# Version 1.8

FROM alpine:3.7
MAINTAINER MarkusMcNugen

VOLUME /downloads
VOLUME /config

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories \
    && echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories \
    && apk add --update bash openvpn iptables shadow apk-tools@edge

RUN usermod -u 99 nobody

RUN buildDeps=" \
        boost \
        boost-build \
		curl \
		g++ \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		qt-dev \
		readline-dev \
		tar \
		xz \
	"; \
    set -x \
    && apk add --update --virtual .build-deps $buildDeps \
    && export LIBTOR_VERSION=$(curl --silent "https://github.com/arvidn/libtorrent/tags" 2>&1 | grep -m 1 'libtorrent-' |  sed -e 's~^[ \t]*~~;s~[ \t]*$~~' | sed -n 's/.*href="\([^"]*\).*/\1/p' | sed 's!.*/!!') \
    && export QBIT_VERSION=$(curl --silent "https://github.com/qbittorrent/qBittorrent/tags" 2>&1 | grep -m 1 'release-' |  sed -e 's~^[ \t]*~~;s~[ \t]*$~~' | sed -n 's/.*href="\([^"]*\).*/\1/p' | sed 's!.*/!!') \
    && curl -L "https://github.com/arvidn/libtorrent/archive/$LIBTOR_VERSION.tar.gz" -o libtor.tar.gz \
    && curl -L "https://github.com/qbittorrent/qBittorrent/archive/$QBIT_VERSION.tar.gz" -o qbittorrent.tar.gz \
    && mkdir -p /usr/src/libtorrent \
    && mkdir -p /usr/src/qbittorrent \
    && tar -xzf libtor.tar.gz -C /usr/src/libtorrent --strip-components=1 \
    && tar -xzf qbittorrent.tar.gz -C /usr/src/qbittorrent --strip-components=1 \
    && rm libtor.tar.gz* \
    && rm qbittorrent.tar.gz* \
    && cd /usr/src/libtorrent/ \
    && b2 install \
    && cd /usr/src/qbittorrent/ \
    && ./configure --disable-gui \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /usr/src/libtorrent \
    && rm -rf /usr/src/qbittorrent \
    && runDeps="$( \
	scanelf --needed --nobanner /usr/local/bin/qbittorrent-nox \
		| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
		| xargs -r apk info --installed \
		| sort -u \
	)" \
    && apk add --virtual .run-deps $runDeps gnutls-utils iptables \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* 

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

# Expose ports and run
EXPOSE 8080
EXPOSE 8999
EXPOSE 8999/udp
CMD ["/bin/bash", "/etc/openvpn/start.sh"]

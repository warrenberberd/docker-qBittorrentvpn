# qBittorrent and OpenVPN
#
# Version 1.8

FROM alpine:edge
MAINTAINER MarkusMcNugen

VOLUME /downloads
VOLUME /config

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories
RUN apk upgrade --no-cache
RUN apk add --no-cache --upgrade coreutils 
RUN apk add --no-cache --upgrade bash 
RUN apk add --no-cache --upgrade openvpn 
RUN apk add --no-cache --upgrade openssl 
RUN apk add --no-cache --upgrade iptables 
RUN apk add --no-cache --upgrade shadow 
RUN apk add --no-cache --upgrade boost-system 
RUN apk add --no-cache --upgrade boost-thread 
RUN apk add --no-cache --upgrade ca-certificates 
RUN apk add --no-cache --upgrade unrar 
RUN apk add --no-cache --upgrade findutils 
RUN apk add --no-cache --upgrade perl 
RUN apk add --no-cache --upgrade gawk 
RUN apk add --no-cache --upgrade pacman 
RUN apk add --no-cache --upgrade net-tools 
RUN apk add --no-cache --upgrade tar
RUN update-ca-certificates

RUN usermod -u 99 nobody

# copy patches
COPY patches/ /tmp/patches

RUN buildDeps=" \
		automake \
		autoconf \
		boost-dev \
		clang \
		curl \
		cmake \
		file \
		g++ \
		git \
		geoip-dev \
		gnutls-dev \
		libtool \
		linux-headers \
		linux-pam-dev \
		make \
		qt5-qttools-dev \
		qt5-qtbase-dev \
		readline-dev \
		xz \
	"; \
    set -x \
    && apk add --update --virtual .build-deps $buildDeps
    
RUN export LIBTOR_VERSION=$(curl --silent "https://github.com/arvidn/libtorrent/tags" 2>&1 | grep -m 1 'libtorrent-' |  sed -e 's~^[t]*~~;s~[t]*$~~' | sed -n 's/.*href="\([^"]*\).*/\1/p' | sed 's!.*/!!') \
&& curl -SL "https://github.com/arvidn/libtorrent/archive/$LIBTOR_VERSION.tar.gz" -o tibtor.tar.gz \
&& mkdir -p /usr/src/libtorrent \
&& tar -xf "tibtor.tar.gz" -C /usr/src/libtorrent --strip-components=1 \
&& rm "tibtor.tar.gz"
WORKDIR /usr/src/libtorrent/
RUN ./autotool.sh
RUN export LDFLAGS=-L/opt/local/lib
RUN export CXXFLAGS=-I/opt/local/include
RUN ./configure --disable-debug --enable-encryption --prefix=/usr --disable-dependency-tracking 
RUN make
RUN make install
RUN QBIT_VERSION=$(curl --silent "https://github.com/qbittorrent/qBittorrent/tags" 2>&1 | grep -m 1 'release-' |  sed -e 's~^[t]*~~;s~[t]*$~~' | sed -n 's/.*href="\([^"]*\).*/\1/p' | sed 's!.*/!!')
RUN curl -SL "https://github.com/qbittorrent/qBittorrent/archive/$QBIT_VERSION.tar.gz" -o qbittorrent.tar.gz
RUN mkdir -p /usr/src/qbittorrent
RUN tar -xf qbittorrent.tar.gz -C /usr/src/qbittorrent --strip-components=1
RUN rm qbittorrent.tar.gz*
WORKDIR /usr/src/qbittorrent/src/app
RUN patch -i /tmp/patches/main.patch
WORKDIR /usr/src/qbittorrent/
RUN ./configure --disable-gui --prefix=/usr
RUN make
RUN make install
WORKDIR /
RUN rm -rf /usr/src/libtorrent
RUN rm -rf /usr/src/qbittorrent
    
RUN runDeps="$( \
	scanelf --needed --nobanner /usr/local/bin/qbittorrent-nox \
		| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
		| xargs -r apk info --installed \
		| sort -u \
	)" \
    && apk add --virtual .run-deps $runDeps gnutls-utils iptables \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

# Expose ports and run
EXPOSE 8080
EXPOSE 8999
EXPOSE 8999/udp
CMD ["/bin/bash", "/etc/openvpn/start.sh"]

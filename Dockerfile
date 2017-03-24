FROM alpine:latest
MAINTAINER Óscar de Arriba <odarriba@gmail.com>

##################
##   BUILDING   ##
##################

# Versions to use
ENV netatalk_version 3.1.11

WORKDIR /

# Prerequisites
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
      bash \
      curl \
      libldap \
      libgcrypt \
      python \
      avahi \
      avahi-tools \
      #dbus \
      #dbus-glib \
      py-dbus \
      linux-pam \
      cracklib \
      db \
      libevent \
      file \
      acl \
      openssl \
      supervisor && \
    apk add --no-cache --virtual .build-deps \
      build-base \
      autoconf \
      automake \
      libtool \
      libgcrypt-dev \
      linux-pam-dev \
      cracklib-dev \
      acl-dev \
      db-dev \
      #dbus-dev \
      libevent-dev && \
    ln -s -f /bin/true /usr/bin/chfn && \
    cd /tmp && \
    curl -o netatalk-${netatalk_version}.tar.gz -L https://downloads.sourceforge.net/project/netatalk/netatalk/${netatalk_version}/netatalk-${netatalk_version}.tar.gz && \
    tar xvf netatalk-${netatalk_version}.tar.gz && \
    cd netatalk-${netatalk_version} && \
    CFLAGS="-Wno-unused-result -O2" ./configure \
      --prefix=/usr \
      --localstatedir=/var/state \
      --sysconfdir=/etc \
      #--with-dbus-sysconf-dir=/etc/dbus-1/system.d/ \
      --with-init-style=debian-sysv \
      --sbindir=/usr/bin \
      --enable-quota \
      --with-tdb \
      --enable-silent-rules \
      --with-cracklib \
      --with-cnid-cdb-backend \
      --enable-pgp-uam \
      --with-acls && \
    make && \
    make install && \
    cd /tmp && \
    rm -rf netatalk-${netatalk_version} netatalk-${netatalk_version}.tar.gz && \
    apk del .build-deps

# Disable dbus for avahi
RUN sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf

# Set avahi hostname to "TimeMachine"
RUN sed -i 's/#host-name=foo/host-name=TimeMachine/g' /etc/avahi/avahi-daemon.conf

# Clean package cache
RUN rm -fr /var/cache/apk/*

RUN mkdir -p /timemachine && \
    mkdir -p /var/log/supervisor

# Create the log file
RUN touch /var/log/afpd.log

ADD entrypoint.sh /entrypoint.sh
ADD avahi/afpd.service /etc/avahi/services/afpd.service
ADD avahi/nsswitch.conf /etc/nsswitch.conf
ADD start_netatalk.sh /start_netatalk.sh
ADD bin/add-account /usr/bin/add-account
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 548 636 9 5353/udp

VOLUME ["/timemachine", "/var/state/netatalk"]

CMD ["/entrypoint.sh"]

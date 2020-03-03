FROM php:7.4.3-fpm-alpine3.10

MAINTAINER Boudy de Geer <boudydegeer@webartisans.es>

ENV \
	SWOOLE_VERSION=4.4.12 \
  PECL_EXTENSIONS="apcu ast ds ev hrtime igbinary imagick lzf lua mongodb msgpack oauth pcov psr redis \
    ssh2-1.2 uuid xdebug xlswriter yaf yaml" \
  PECL_BUNDLE="memcached event" \
  PHP_EXTENSIONS="bcmath bz2 calendar exif gd gettext gmp imap intl ldap mysqli pcntl pdo_mysql pgsql pdo_pgsql \
    soap sockets swoole swoole_async sysvshm sysvmsg sysvsem tidy zip"

RUN \
# deps
  apk add -U --no-cache --virtual temp \
    # dev deps
    autoconf g++ file re2c make zlib-dev libtool pcre-dev libxml2-dev bzip2-dev libzip-dev \
      icu-dev gettext-dev imagemagick-dev openldap-dev libpng-dev gmp-dev yaml-dev postgresql-dev \
      libxml2-dev tidyhtml-dev libmemcached-dev libssh2-dev libevent-dev libev-dev lua-dev \
    # prod deps
    && apk add --no-cache icu gettext imagemagick libzip libbz2 libxml2-utils openldap-back-mdb openldap yaml \
      libpq tidyhtml imap-dev libmemcached libssh2 libevent libev lua \
#
# php extensions
  && docker-php-source extract \
    && pecl channel-update pecl.php.net \
    && pecl install $PECL_EXTENSIONS \
    && cd /usr/src/php/ext/ \
    && for BUNDLE_EXT in $PECL_BUNDLE; do pecl bundle $BUNDLE_EXT; done \
    && docker-php-ext-enable $(echo $PECL_EXTENSIONS | sed -E 's/\-[^ ]+//g') opcache \
    # swoole
    && curl -sSLo swoole.tar.gz https://github.com/swoole/swoole-src/archive/v$SWOOLE_VERSION.tar.gz \
      && curl -sSLo swoole_async.tar.gz https://github.com/swoole/ext-async/archive/v$SWOOLE_VERSION.tar.gz \
      && tar xzf swoole.tar.gz && tar xzf swoole_async.tar.gz \
      && mv swoole-src-$SWOOLE_VERSION swoole && mv ext-async-$SWOOLE_VERSION swoole_async \
      && rm -f swoole.tar.gz swoole_async.tar.gz \
  && docker-php-source delete \
#
# composer
  && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
#
# cleanup
  && apk del temp \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/*

# docker-php-ext-disable
COPY ./scripts/docker-php-ext-disable.sh /usr/local/bin/docker-php-ext-disable

# ext
COPY ./scripts/extensions.php /scripts/extensions.php
RUN php -f /scripts/extensions.php

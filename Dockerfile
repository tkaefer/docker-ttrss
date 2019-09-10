FROM php:7.3-fpm-alpine
MAINTAINER Tobias Kaefer <tobias@tkaefer.de>

WORKDIR /var/www
RUN apk --no-cache add curl supervisor libcurl sed libpng postgresql openldap libmcrypt icu \
  && apk --no-cache add --virtual .build-dependencies make curl-dev git libpng-dev postgresql-dev openldap-dev libmcrypt-dev autoconf build-base icu-dev \
  && docker-php-ext-configure intl \
  && docker-php-ext-install curl gd json pgsql ldap mysqli pdo_pgsql pdo_mysql pcntl intl \
  && pecl install mcrypt-1.0.2 \
  && docker-php-ext-enable mcrypt \
  && curl -SL https://git.tt-rss.org/git/tt-rss/archive/master.tar.gz | tar xzC /var/www --strip-components 1 \
  && chown www-data:www-data -R /var/www \
  && git clone https://github.com/hydrian/TTRSS-Auth-LDAP.git /TTRSS-Auth-LDAP \
  && cp -r /TTRSS-Auth-LDAP/plugins/auth_ldap /var/www/plugins.local \
  && ls -la /var/www/plugins \
  && cp config.php-dist config.php \
  && curl -SL https://github.com/levito/tt-rss-feedly-theme/archive/master.tar.gz | tar xzC /usr/src \
  && cp -r /usr/src/tt-rss-feedly-theme-master/feedly* /var/www/themes.local \
  && curl -SL https://github.com/DigitalDJ/tinytinyrss-fever-plugin/archive/master.tar.gz  | tar xzC /usr/src \
  && cp -r /usr/src/tinytinyrss-fever-plugin-master /var/www/plugins.local/fever \
  && rm -rf /usr/src/* \
  && apk del .build-dependencies build-base


# expose only nginx HTTP port
EXPOSE 9000

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss
ENV DB_HOST database
ENV DB_PORT 5432

# auth method, options are: internal, ldap
ENV AUTH_METHOD internal

ENV PHP_EXECUTABLE /usr/local/bin/php

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD configure.php /configure.php
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD entrypoint.sh /entrypoint.sh

VOLUME /var/www

ENTRYPOINT ["/entrypoint.sh"]
CMD [""]

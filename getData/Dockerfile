FROM php:5.6-apache

RUN apt-get update -qq && apt-get dist-upgrade -y

# See https://github.com/docker-library/docs/tree/master/php

RUN apt-get install -y \
    python-minimal \
    vim \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    && docker-php-ext-install iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs build-essential \
    && npm install -g csvtojson

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www/html

COPY ./www/bin/q /usr/bin/q
COPY ./launch-server.sh /usr/bin/launch-server.sh
ADD ./www /var/www/html

RUN chmod 755 /usr/bin/q \
  && chmod -R 777 /var/www/html \
  && chmod 755 /usr/bin/launch-server.sh

RUN mkdir -p /opt/data
VOLUME /opt/data

WORKDIR /var/www/html

EXPOSE 80

CMD ["/usr/bin/launch-server.sh"]

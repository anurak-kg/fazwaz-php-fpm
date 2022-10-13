FROM php:8.1.11-fpm
RUN  apt-get update \
    && apt-get install -y --no-install-recommends libxpm-dev libxml2-dev jpegoptim optipng pngquant gifsicle screen \
    libjpeg62-turbo-dev libpng-dev libfreetype6-dev libmagickwand-dev libmemcached-dev libcurl4-openssl-dev pkg-config \
    libssl-dev git libzip-dev nano iputils-ping traceroute vim default-mysql-client wget libfcgi-bin procps\
    && apt-get clean

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-xpm=/usr/include/ \
    && pecl install xdebug imagick igbinary mongodb redis\
    && docker-php-ext-enable imagick igbinary mongodb redis opcache \
    && docker-php-ext-install pdo_mysql mysqli pcntl intl bcmath fileinfo exif zip gd sockets

# Memcache
#RUN git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached \
#        && docker-php-ext-configure memcached --enable-memcached-igbinary  \
#        && docker-php-ext-install memcached

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && BIN_PATH=/usr/local/bin/ \
    && chmod +x /usr/local/bin/composer \
    && curl -LsS https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar -o ${BIN_PATH}phpcs \
    && chmod a+x ${BIN_PATH}phpcs \
    && curl -LsS https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar -o ${BIN_PATH}phpcbf \
    && chmod a+x ${BIN_PATH}phpcbf


# Node Js and GEOS Lib
RUN curl -sL https://deb.nodesource.com/setup_16.x |  bash -  \
    && apt-get update \
    && apt-get install -y libgeos-dev  gnupg2 nodejs -y \
    && apt-get clean

# PHP Geos
RUN git clone https://github.com/ModelTech/php-geos.git \
    && ( \
    cd php-geos \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
  ) \
  && rm -r php-geos && docker-php-ext-enable geos

# Tideways APM
#RUN echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' > /etc/apt/sources.list.d/tideways.list && \
#    curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | apt-key add - && \
#    apt-get update && \
#    DEBIAN_FRONTEND=noninteractive apt-get -yq install tideways-php && \
#    apt-get autoremove --assume-yes && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# FPM Check
RUN wget -O /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck && \
    chmod +x /usr/local/bin/php-fpm-healthcheck

COPY entryscript.sh /usr/local/bin/
WORKDIR /var/www/
RUN chmod +x /usr/local/bin/entryscript.sh

ENTRYPOINT ["entryscript.sh"]
CMD ["php-fpm"]

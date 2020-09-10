FROM php:7.4.10-fpm
RUN  apt-get update \
    && apt-get install -y --no-install-recommends libxpm-dev libxml2-dev jpegoptim optipng pngquant gifsicle screen \
    libjpeg62-turbo-dev libpng-dev  libfreetype6-dev libmagickwand-dev libmemcached-dev libcurl4-openssl-dev pkg-config \
    libssl-dev git libzip-dev nano iputils-ping traceroute vim

RUN docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-xpm=/usr/include/ \
    && pecl install xdebug imagick igbinary mongodb redis\
    && docker-php-ext-enable imagick opcache igbinary mongodb redis \
    && docker-php-ext-install pdo_mysql mysqli pcntl intl bcmath fileinfo exif zip gd opcache

RUN git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached \
        && docker-php-ext-configure memcached --enable-memcached-igbinary  \
        && docker-php-ext-install memcached

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && BIN_PATH=/usr/local/bin/\
    && curl -LsS https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar -o ${BIN_PATH}phpcs \
    && chmod a+x ${BIN_PATH}phpcs \
    && curl -LsS https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar -o ${BIN_PATH}phpcbf \
    && chmod a+x ${BIN_PATH}phpcbf

#ENV NODE_VERSION 12.18.3
RUN curl -sL https://deb.nodesource.com/setup_lts.x |  bash -

# OSGeo lib (libgeo) (php-geos)
RUN apt-get update && apt-get install -y libgeos-dev nodejs
RUN git clone https://github.com/libgeos/php-geos.git \
  && ( \
    cd php-geos \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
  ) \
  && rm -r php-geos && docker-php-ext-enable geos

RUN  composer global require "hirak/prestissimo"

RUN apt-get install gnupg2 -y
RUN echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' > /etc/apt/sources.list.d/tideways.list && \
    curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | apt-key add - && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install tideways-php && \
    apt-get autoremove --assume-yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entryscript.sh /usr/local/bin/
WORKDIR /var/www/
RUN chmod +x /usr/local/bin/entryscript.sh

ENTRYPOINT ["entryscript.sh"]
CMD ["php-fpm"]

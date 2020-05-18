FROM php:7.4.6-fpm
RUN  apt-get update \
    && apt-get install -y --no-install-recommends libxpm-dev libxml2-dev jpegoptim optipng pngquant gifsicle screen \
    libjpeg62-turbo-dev libpng-dev  libfreetype6-dev libmagickwand-dev libmemcached-dev libcurl4-openssl-dev pkg-config \
    libssl-dev git libzip-dev nano iputils-ping traceroute vim

RUN docker-php-ext-configure opcache --enable-opcache \
#    For PHP7.3
#    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
#    For PHP7.4
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

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 10.16.3

# install nvm
# https://github.com/creationix/nvm#install-script
# RUN cd /tmp \
#    && git clone https://github.com/tideways/php-profiler-extension.git \
#    && cd /tmp/php-profiler-extension \
#    && phpize \
#    && ./configure \
#    && make && make install


RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.5/install.sh | bash

# install node and npm
RUN . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && pecl clear-cache
# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# OSGeo lib (libgeo) (php-geos)
RUN apt-get update && apt-get install -y libgeos-dev
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
COPY entryscript.sh /usr/local/bin/
WORKDIR /var/www/
ENTRYPOINT ["entryscript.sh"]
CMD ["php-fpm"]

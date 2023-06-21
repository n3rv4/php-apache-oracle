FROM php:8.1-apache

# Set working directory
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    libaio1 libaio-dev libfreetype6-dev libicu-dev libjpeg62-turbo-dev libldap2-dev libonig-dev libpng-dev libzip-dev \
    build-essential gifsicle jpegoptim locales optipng pngquant \
    curl cron git imagemagick sudo telnet unzip vim wget zip \
    && a2enmod rewrite \
    && curl https://get.volta.sh | bash

RUN apt-get wget https://www.python.org/ftp/python/2.7.8/Python-2.7.8.tgz\
    && tar -zxvf Python-2.7.8.tgz\
    && cd Python-2.7.8\
    && ./configure \
    && ./make \
    && ./make install

COPY _php/timezone.ini /usr/local/etc/php/conf.d/timezone.ini
COPY _php/vars.ini /usr/local/etc/php/conf.d/vars.ini

# Install extensions
RUN    docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install exif gd intl mbstring opcache pcntl pdo_mysql zip \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && pecl install -o -f redis \
    && docker-php-ext-enable redis

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/pear

# Install Oracle Instantclient
RUN mkdir /opt/oracle
RUN  wget https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-basic-linux.x64-21.8.0.0.0dbru.zip \
  && wget https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-sdk-linux.x64-21.8.0.0.0dbru.zip \
  && wget https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-sqlplus-linux.x64-21.8.0.0.0dbru.zip \
  && unzip instantclient-basic-linux.x64-21.8.0.0.0dbru.zip -d /opt/oracle \
  && unzip instantclient-sdk-linux.x64-21.8.0.0.0dbru.zip -d /opt/oracle \
  && unzip instantclient-sqlplus-linux.x64-21.8.0.0.0dbru.zip -d /opt/oracle \
  && mv /opt/oracle/instantclient_21_8 /opt/oracle/instantclient \
  && rm -rf *.zip

RUN sh -c "echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf" \
  && ldconfig

#add oracle instantclient path to environment
ENV ORACLE_BASE /opt/oracle/instantclient/
ENV LD_LIBRARY_PATH /opt/oracle/instantclient/
ENV TNS_ADMIN /opt/oracle/instantclient/
ENV ORACLE_HOME /opt/oracle/instantclient/


# Install Oracle extensions
RUN docker-php-ext-configure oci8 --with-oci8=instantclient,$ORACLE_HOME && docker-php-ext-install oci8
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,$ORACLE_HOME && docker-php-ext-install pdo_oci

EXPOSE 80 443
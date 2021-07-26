FROM php:7.3-fpm-buster

LABEL org.opencontainers.image.authors="franco.novello@gmail.com"

RUN rm -rf /var/lib/apt/lists/* 


RUN apt-get update && apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        mc -y \
        libzip-dev -y\
        procps -y \
        inetutils-ping \
        cron -y \
        libxml2-dev -y \
        libaio1 wget && apt-get clean autoclean && apt-get autoremove --yes &&  rm -rf /var/lib/{apt,dpkg,cache,log}/ 


RUN apt-get install nginx -y


#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ORACLE oci 
RUN mkdir /opt/oracle \
    && cd /opt/oracle     
    
ADD serverconfig/oci8/instantclient-basic-linux.x64-12.1.0.2.0.zip /opt/oracle
ADD serverconfig/oci8/instantclient-sdk-linux.x64-12.1.0.2.0.zip /opt/oracle

# Install Oracle Instantclient
RUN  unzip /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_1/libclntshcore.so.12.1 /opt/oracle/instantclient_12_1/libclntshcore.so \
    && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so \
    && rm -rf /opt/oracle/*.zip
    
ENV LD_LIBRARY_PATH  /opt/oracle/instantclient_12_1:${LD_LIBRARY_PATH}
    
# Install Oracle extensions
# RUN echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8 \ 
RUN echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8-2.2.0  \   
      && docker-php-ext-enable \
               oci8 \ 
       && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1,12.1 \
       && docker-php-ext-install \
               pdo_oci \
               zip \
               gd \
               soap \
               mbstring

COPY serverconfig/entrypoint.sh /etc/entrypoint.sh

#Replace for own env file
COPY serverconfig/configuracion.php /var/www/html/config/configuracion.php

WORKDIR /var/www/html

EXPOSE 80 443

ENTRYPOINT ["sh", "/etc/entrypoint.sh"]

# CMD ["nginx", "-g", "daemon off;"]
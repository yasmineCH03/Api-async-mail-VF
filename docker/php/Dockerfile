FROM ubuntu:latest
LABEL authors="yassmine"
FROM php:8.2-fpm

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libssl-dev \
    librabbitmq-dev

# Extensions PHP
RUN docker-php-ext-install \
    pdo_mysql \
    zip \
    intl \
    opcache

# Installation de Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Installation de l'extension MongoDB
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Installation de l'extension AMQP pour RabbitMQ
RUN pecl install amqp && docker-php-ext-enable amqp

WORKDIR /var/www/symfony

CMD ["php-fpm"]
ENTRYPOINT ["top", "-b"]
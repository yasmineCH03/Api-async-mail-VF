FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libssl-dev \
    librabbitmq-dev

# PHP extensions
RUN docker-php-ext-install \
    zip \
    intl \
    opcache

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install MongoDB extension
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Install AMQP extension for RabbitMQ
RUN pecl install amqp && docker-php-ext-enable amqp

WORKDIR /var/www/symfony

CMD ["php-fpm"]

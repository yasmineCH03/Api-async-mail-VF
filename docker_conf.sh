#!/bin/bash

# Create docker-compose.yml file
cat > docker-compose.yml << 'EOL'
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "8000:80"  # Changed to port 8000 to match your curl command
    volumes:
      - ./:/var/www/symfony
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
    networks:
      - app-network

  php:
    build:
      context: .
      dockerfile: ./docker/php/Dockerfile
    volumes:
      - ./:/var/www/symfony
    depends_on:
      - mongodb
      - rabbitmq
    networks:
      - app-network

  worker:
    build:
      context: .
      dockerfile: ./docker/php/Dockerfile
    volumes:
      - ./:/var/www/symfony
    depends_on:
      - php
      - rabbitmq
      - mongodb
    command: ["php", "bin/console", "messenger:consume", "async_email", "--limit=10", "-vv"]
    networks:
      - app-network

  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "15672:15672"  # Management interface
      - "5672:5672"    # AMQP port
    environment:
      - RABBITMQ_DEFAULT_USER=guest
      - RABBITMQ_DEFAULT_PASS=guest
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - app-network

  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"  # MongoDB port
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_DATABASE=email_api
    networks:
      - app-network
      
  mongo-express:
    image: mongo-express
    restart: always
    ports:
      - "8081:8081"
    environment:
      - ME_CONFIG_MONGODB_SERVER=mongodb
      - ME_CONFIG_MONGODB_PORT=27017
    depends_on:
      - mongodb
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  rabbitmq_data:
  mongodb_data:
EOL

# Create directories
mkdir -p docker/nginx
mkdir -p docker/php

# Create NGINX config
cat > docker/nginx/default.conf << 'EOL'
server {
    listen 80;
    server_name localhost;
    root /var/www/symfony/public;

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass php:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $document_root;
        internal;
    }

    location ~ \.php$ {
        return 404;
    }

    error_log /var/log/nginx/project_error.log;
    access_log /var/log/nginx/project_access.log;
}
EOL

# Create PHP Dockerfile
cat > docker/php/Dockerfile << 'EOL'
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
EOL

echo "Docker configuration files created successfully!"
echo "Next steps:"
echo "1. Run 'docker-compose down' to stop any running containers"
echo "2. Run 'docker-compose up -d' to start the services with the new configuration"
echo "3. Access MongoDB UI at http://localhost:8081"
echo "4. Test API endpoints with:"
echo "   - POST: curl -X POST http://localhost:8000/emails -H \"Content-Type: application/json\" -d '{\"to\": \"test@example.com\", \"subject\": \"Test email\", \"body\": \"<h1>Hello</h1><p>This is a test email</p>\"}'"
echo "   - GET: curl http://localhost:8000/emails/{id}"
echo "5. Access RabbitMQ management at http://localhost:15672 (guest/guest)"
EOL

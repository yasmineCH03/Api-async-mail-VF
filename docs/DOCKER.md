# 🐳 Documentation Docker

Ce guide vous explique comment utiliser Docker pour développer, tester et déployer l'API Async Email.

## 📋 Table des Matières

- [Vue d'ensemble](#vue-densemble)
- [Services Docker](#services-docker)
- [Développement Local](#développement-local)
- [Configuration](#configuration)
- [Déploiement](#déploiement)
- [Troubleshooting](#troubleshooting)

## 🏗️ Vue d'ensemble

L'API Async Email utilise Docker Compose pour orchestrer plusieurs services :

```mermaid
graph TB
    subgraph "Docker Compose"
        Nginx[Nginx :80]
        PHP[PHP-FPM :9000]
        MongoDB[MongoDB :27017]
        RabbitMQ[RabbitMQ :5672]
        Worker[Worker Process]
        MongoExpress[MongoDB Express :8081]
        Mailpit[Mailpit :1025/8025]
    end
    
    Client[Client] --> Nginx
    Nginx --> PHP
    PHP --> MongoDB
    PHP --> RabbitMQ
    RabbitMQ --> Worker
    Worker --> MongoDB
    Worker --> Mailpit
```

## 🐳 Services Docker

### 1. **Nginx** (Reverse Proxy)

```yaml
nginx:
  image: nginx:1.29
  ports:
    - "8000:80"
  volumes:
    - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    - ./skeleton/public:/var/www/symfony/skeleton/public
  depends_on:
    - php
```

**Responsabilités :**
- Serveur web principal
- Reverse proxy vers PHP-FPM
- Gestion des requêtes statiques
- Configuration SSL (production)

### 2. **PHP-FPM** (Application)

```yaml
php:
  build: ./docker/php
  volumes:
    - ./skeleton:/var/www/symfony/skeleton
  environment:
    - APP_ENV=dev
    - APP_DEBUG=true
  depends_on:
    - mongodb
    - rabbitmq
```

**Responsabilités :**
- Exécution de l'application Symfony
- Traitement des requêtes API
- Gestion des sessions
- Cache et logs

### 3. **MongoDB** (Base de Données)

```yaml
mongodb:
  image: mongo:5.0
  ports:
    - "27017:27017"
  volumes:
    - mongodb_data:/data/db
  environment:
    - MONGO_INITDB_DATABASE=email_api
```

**Responsabilités :**
- Stockage des emails et métadonnées
- Persistance des données
- Requêtes et indexation
- Réplication (production)

### 4. **RabbitMQ** (Message Queue)

```yaml
rabbitmq:
  image: rabbitmq:3.8-management
  ports:
    - "5672:5672"
    - "15672:15672"
  environment:
    - RABBITMQ_DEFAULT_USER=guest
    - RABBITMQ_DEFAULT_PASS=guest
  volumes:
    - rabbitmq_data:/var/lib/rabbitmq
```

**Responsabilités :**
- Queue de messages asynchrones
- Découplage des services
- Retry automatique
- Monitoring des queues

### 5. **Worker** (Traitement Asynchrone)

```yaml
worker:
  build: ./docker/php
  command: ["php", "skeleton/bin/console", "messenger:consume", "async_email", "--limit=10", "-vv"]
  volumes:
    - ./skeleton:/var/www/symfony/skeleton
  depends_on:
    - php
    - mongodb
    - rabbitmq
    - mailpit
```

**Responsabilités :**
- Consommation des messages RabbitMQ
- Envoi des emails via SMTP
- Mise à jour des statuts
- Gestion des erreurs

### 6. **MongoDB Express** (Interface d'Administration)

```yaml
mongo-express:
  image: mongo-express
  ports:
    - "8081:8081"
  environment:
    - ME_CONFIG_MONGODB_SERVER=mongodb
    - ME_CONFIG_MONGODB_PORT=27017
    - ME_CONFIG_BASICAUTH=false
  depends_on:
    - mongodb
```

**Responsabilités :**
- Interface web pour MongoDB
- Visualisation des données
- Requêtes et debugging
- Administration de la base

### 7. **Mailpit** (Serveur SMTP de Test)

```yaml
mailpit:
  image: axllent/mailpit
  ports:
    - "1025:1025"  # SMTP
    - "8025:8025"  # Web UI
  networks:
    - app-network
```

**Responsabilités :**
- Serveur SMTP de test
- Capture des emails envoyés
- Interface web de visualisation
- Debugging des emails

## 🚀 Développement Local

### 1. **Prérequis**

```bash
# Vérifier Docker
docker --version
docker-compose --version

# Vérifier les ports disponibles
netstat -tulpn | grep -E ':(80|8000|27017|5672|8081|8025)'
```

### 2. **Démarrage Rapide**

```bash
# Cloner le projet
git clone https://github.com/votre-username/async-email-api.git
cd async-email-api

# Démarrer tous les services
docker-compose up -d

# Vérifier le statut
docker-compose ps
```

### 3. **Premier Déploiement**

```bash
# Construire les images
docker-compose build

# Démarrer les services
docker-compose up -d

# Installer les dépendances
docker-compose exec php composer install

# Vider le cache
docker-compose exec php php bin/console cache:clear

# Vérifier les logs
docker-compose logs -f
```

### 4. **Développement Quotidien**

```bash
# Démarrer l'environnement
docker-compose up -d

# Accéder au container PHP
docker-compose exec php bash

# Lancer les tests
docker-compose exec php php bin/phpunit

# Vider le cache
docker-compose exec php php bin/console cache:clear

# Arrêter l'environnement
docker-compose down
```

## ⚙️ Configuration

### 1. **Variables d'Environnement**

```bash
# .env.local
APP_ENV=dev
APP_DEBUG=true

# Base de données
MONGODB_URL=mongodb://mongodb:27017
MONGODB_DB=email_api

# Queue de messages
MESSENGER_TRANSPORT_DSN=amqp://guest:guest@rabbitmq:5672/%2f/emails

# SMTP
MAILER_DSN=smtp://mailpit:1025

# Cache
CACHE_DSN=redis://redis:6379
```

### 2. **Configuration Nginx**

```nginx
# docker/nginx/default.conf
server {
    listen 80;
    server_name localhost;
    root /var/www/symfony/skeleton/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

### 3. **Configuration PHP**

```dockerfile
# docker/php/Dockerfile
FROM php:8.2-fpm

# Installer les extensions PHP
RUN docker-php-ext-install pdo pdo_mysql

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Installer les dépendances MongoDB
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Installer les dépendances RabbitMQ
RUN apt-get update && apt-get install -y librabbitmq-dev
RUN pecl install amqp && docker-php-ext-enable amqp

# Configuration PHP
COPY docker/php/php.ini /usr/local/etc/php/php.ini
```

## 🚀 Déploiement

### 1. **Environnement de Production**

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  nginx:
    image: nginx:1.29
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/prod.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - php

  php:
    build: ./docker/php
    environment:
      - APP_ENV=prod
      - APP_DEBUG=false
    volumes:
      - ./skeleton:/var/www/symfony/skeleton
    depends_on:
      - mongodb
      - rabbitmq

  mongodb:
    image: mongo:5.0
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=password
    volumes:
      - mongodb_data:/data/db
    ports:
      - "27017:27017"

  rabbitmq:
    image: rabbitmq:3.8-management
    environment:
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=password
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"

volumes:
  mongodb_data:
  rabbitmq_data:
```

### 2. **Déploiement avec Docker Swarm**

```bash
# Initialiser Swarm
docker swarm init

# Déployer le stack
docker stack deploy -c docker-compose.prod.yml async-email-api

# Vérifier le statut
docker stack services async-email-api
```

### 3. **Déploiement avec Kubernetes**

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: async-email-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: async-email-api
  template:
    metadata:
      labels:
        app: async-email-api
    spec:
      containers:
      - name: php
        image: async-email-api:latest
        ports:
        - containerPort: 9000
        env:
        - name: APP_ENV
          value: "prod"
        - name: MONGODB_URL
          value: "mongodb://mongodb:27017"
```

## 🔧 Troubleshooting

### 1. **Problèmes Courants**

#### Port déjà utilisé
```bash
# Vérifier les ports utilisés
netstat -tulpn | grep :8000

# Arrêter le service qui utilise le port
sudo systemctl stop nginx

# Ou changer le port dans docker-compose.yml
ports:
  - "8001:80"
```

#### Container ne démarre pas
```bash
# Vérifier les logs
docker-compose logs php

# Redémarrer le container
docker-compose restart php

# Reconstruire l'image
docker-compose build --no-cache php
```

#### Problème de permissions
```bash
# Corriger les permissions
docker-compose exec php chown -R www-data:www-data /var/www/symfony/skeleton/var
docker-compose exec php chmod -R 755 /var/www/symfony/skeleton/var
```

### 2. **Commandes de Debug**

```bash
# Vérifier le statut des services
docker-compose ps

# Voir les logs en temps réel
docker-compose logs -f

# Accéder au container
docker-compose exec php bash

# Vérifier la connectivité réseau
docker-compose exec php ping mongodb
docker-compose exec php ping rabbitmq

# Vérifier les volumes
docker volume ls
docker volume inspect async-email-api_mongodb_data
```

### 3. **Nettoyage**

```bash
# Arrêter et supprimer les containers
docker-compose down

# Supprimer les volumes (ATTENTION: perte de données)
docker-compose down -v

# Supprimer les images
docker-compose down --rmi all

# Nettoyer le système Docker
docker system prune -a
```

## 📊 Monitoring

### 1. **Métriques Docker**

```bash
# Utilisation des ressources
docker stats

# Espace disque
docker system df

# Images et containers
docker images
docker ps -a
```

### 2. **Logs Centralisés**

```yaml
# docker-compose.yml
services:
  php:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 3. **Health Checks**

```yaml
# docker-compose.yml
services:
  php:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 🔒 Sécurité

### 1. **Secrets Docker**

```bash
# Créer un secret
echo "mon_mot_de_passe_secret" | docker secret create db_password -

# Utiliser le secret
services:
  mongodb:
    secrets:
      - db_password
    environment:
      - MONGO_INITDB_ROOT_PASSWORD_FILE=/run/secrets/db_password
```

### 2. **Réseau Sécurisé**

```yaml
# docker-compose.yml
networks:
  app-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 3. **Images Sécurisées**

```dockerfile
# Utiliser des images officielles
FROM php:8.2-fpm-alpine

# Utiliser un utilisateur non-root
RUN adduser -D -s /bin/sh appuser
USER appuser

# Supprimer les packages inutiles
RUN apk del build-dependencies
```

## 📚 Ressources

- [Documentation Docker](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Docker Swarm](https://docs.docker.com/engine/swarm/)
- [Kubernetes](https://kubernetes.io/docs/)
- [Best Practices Docker](https://docs.docker.com/develop/dev-best-practices/)

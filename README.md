# 📧 Async Email API - Symfony 6

[![Symfony](https://img.shields.io/badge/Symfony-6.x-green.svg)](https://symfony.com)
[![PHP](https://img.shields.io/badge/PHP-8.1+-blue.svg)](https://php.net)
[![MongoDB](https://img.shields.io/badge/MongoDB-5.0+-green.svg)](https://mongodb.com)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-3.8+-orange.svg)](https://rabbitmq.com)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://docker.com)

Une API REST moderne et scalable pour l'envoi d'emails asynchrones, développée avec Symfony 6, MongoDB, RabbitMQ et Docker.

## 🚀 Fonctionnalités

- **API REST** : Endpoints pour l'envoi et le suivi d'emails
- **Traitement Asynchrone** : Queue RabbitMQ pour un traitement non-bloquant
- **Base de données** : MongoDB pour le stockage et le suivi des emails
- **Containerisation** : Docker Compose pour un déploiement facile
- **Monitoring** : Interfaces web pour le debugging et la surveillance
- **Validation** : Validation robuste des données d'entrée
- **Tracking** : ID de suivi unique pour chaque email

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client API    │───▶│   Symfony API   │───▶│   RabbitMQ      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │    MongoDB      │    │  Worker Process │
                       │   (Storage)     │    │  (Email Sender) │
                       └─────────────────┘    └─────────────────┘
```

## 📋 Prérequis

- Docker & Docker Compose
- Git

## 🛠️ Installation

### 1. Cloner le projet
```bash
git clone https://github.com/votre-username/async-email-api.git
cd async-email-api
```

### 2. Démarrer les services
```bash
docker-compose up -d
```

### 3. Vérifier le statut
```bash
docker-compose ps
```

## 🚀 Utilisation

### Envoyer un email
```bash
curl -X POST http://localhost:8000/emails \
  -H "Content-Type: application/json" \
  -d '{
    "to": "destinataire@example.com",
    "subject": "Sujet de l'\''email",
    "body": "Contenu de l'\''email en HTML ou texte"
  }'
```

**Réponse :**
```json
{
  "message": "Email queued successfully",
  "tracking_id": "email_68c1f5335a1276.86560359"
}
```

### Vérifier le statut d'un email
```bash
curl -X GET http://localhost:8000/emails/email_68c1f5335a1276.86560359
```

**Réponse :**
```json
{
  "tracking_id": "email_68c1f5335a1276.86560359",
  "to": "destinataire@example.com",
  "subject": "Sujet de l'email",
  "status": "sent",
  "created_at": "2025-09-10 22:01:23"
}
```

## 📊 Interfaces de Monitoring

- **API** : http://localhost:8000
- **MongoDB Express** : http://localhost:8081
- **Mailpit** (Email Testing) : http://localhost:8025

## 🔧 Configuration

### Variables d'environnement
```env
# MongoDB
MONGODB_URL=mongodb://mongodb:27017
MONGODB_DB=email_api

# RabbitMQ
MESSENGER_TRANSPORT_DSN=amqp://guest:guest@rabbitmq:5672/%2f/emails

# SMTP
MAILER_DSN=smtp://mailpit:1025
```

## 📁 Structure du Projet

```
async-email-api/
├── docker/                    # Configuration Docker
│   ├── nginx/
│   └── php/
├── skeleton/                  # Application Symfony
│   ├── src/
│   │   ├── Controller/        # Contrôleurs API
│   │   ├── Document/          # Entités MongoDB
│   │   ├── Message/           # Messages RabbitMQ
│   │   ├── MessageHandler/    # Handlers de messages
│   │   └── Service/           # Services métier
│   ├── config/                # Configuration Symfony
│   └── public/                # Point d'entrée web
├── docker-compose.yml         # Orchestration des services
└── README.md                  # Documentation
```

## 🧪 Tests

### Test de l'API
```bash
# Test d'envoi d'email
curl -X POST http://localhost:8000/emails \
  -H "Content-Type: application/json" \
  -d '{"to": "test@example.com", "subject": "Test", "body": "Hello World!"}'

# Test de validation (email invalide)
curl -X POST http://localhost:8000/emails \
  -H "Content-Type: application/json" \
  -d '{"to": "invalid-email", "subject": "Test", "body": "Hello World!"}'

# Test de validation (champs manquants)
curl -X POST http://localhost:8000/emails \
  -H "Content-Type: application/json" \
  -d '{"subject": "Test", "body": "Hello World!"}'
```

## 📈 Statuts des Emails

- **`queued`** : Email en attente de traitement
- **`sent`** : Email envoyé avec succès
- **`error`** : Erreur lors de l'envoi

## 🛡️ Sécurité

- Validation stricte des données d'entrée
- Validation du format email
- Gestion des erreurs sans exposition de données sensibles
- Containerisation pour l'isolation

## 🚀 Déploiement

### Production
1. Modifier les variables d'environnement
2. Configurer un serveur SMTP réel
3. Déployer avec Docker Compose
4. Configurer un reverse proxy (Nginx)

### Variables de production
```env
MAILER_DSN=smtp://user:password@smtp.example.com:587
MONGODB_URL=mongodb://user:password@mongodb:27017/dbname
```

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👨‍💻 Auteur

**Votre Nom**
- GitHub: [@votre-username](https://github.com/votre-username)
- LinkedIn: [Votre Profil](https://linkedin.com/in/votre-profil)

## 🙏 Remerciements

- [Symfony](https://symfony.com) pour le framework
- [MongoDB](https://mongodb.com) pour la base de données
- [RabbitMQ](https://rabbitmq.com) pour la queue de messages
- [Docker](https://docker.com) pour la containerisation

---

⭐ N'hésitez pas à donner une étoile si ce projet vous a aidé !
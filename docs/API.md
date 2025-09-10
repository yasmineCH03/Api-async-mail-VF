# 📚 Documentation API

## Vue d'ensemble

L'API Async Email fournit des endpoints REST pour l'envoi et le suivi d'emails de manière asynchrone.

**Base URL :** `http://localhost:8000`

## 🔐 Authentification

Actuellement, l'API ne nécessite pas d'authentification. Pour un usage en production, il est recommandé d'ajouter un système d'authentification (JWT, API Key, etc.).

## 📨 Endpoints

### 1. Envoyer un Email

**POST** `/emails`

Envoie un email de manière asynchrone et retourne un ID de suivi.

#### Paramètres de la requête

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| `to` | string | ✅ | Adresse email du destinataire |
| `subject` | string | ✅ | Sujet de l'email |
| `body` | string | ✅ | Contenu de l'email (HTML ou texte) |

#### Exemple de requête

```bash
curl -X POST http://localhost:8000/emails \
  -H "Content-Type: application/json" \
  -d '{
    "to": "user@example.com",
    "subject": "Bienvenue !",
    "body": "<h1>Bienvenue sur notre plateforme</h1><p>Merci de vous être inscrit.</p>"
  }'
```

#### Réponse de succès (200)

```json
{
  "message": "Email queued successfully",
  "tracking_id": "email_68c1f5335a1276.86560359"
}
```

#### Réponses d'erreur

**400 Bad Request - Paramètres manquants**
```json
{
  "error": "Missing required parameters: to, subject, body"
}
```

**400 Bad Request - Email invalide**
```json
{
  "error": "Invalid email address"
}
```

**400 Bad Request - Champs vides**
```json
{
  "error": "Subject cannot be empty"
}
```

**500 Internal Server Error**
```json
{
  "error": "Internal server error message"
}
```

### 2. Récupérer le Statut d'un Email

**GET** `/emails/{tracking_id}`

Récupère le statut et les détails d'un email via son ID de suivi.

#### Paramètres de l'URL

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| `tracking_id` | string | ✅ | ID de suivi unique de l'email |

#### Exemple de requête

```bash
curl -X GET http://localhost:8000/emails/email_68c1f5335a1276.86560359
```

#### Réponse de succès (200)

```json
{
  "tracking_id": "email_68c1f5335a1276.86560359",
  "to": "user@example.com",
  "subject": "Bienvenue !",
  "status": "sent",
  "created_at": "2025-09-10 22:01:23"
}
```

#### Réponse d'erreur

**404 Not Found**
```json
{
  "error": "Email not found"
}
```

## 📊 Statuts des Emails

| Statut | Description |
|--------|-------------|
| `queued` | Email en attente de traitement dans la queue |
| `sent` | Email envoyé avec succès |
| `error` | Erreur lors de l'envoi de l'email |

## 🔍 Codes de Statut HTTP

| Code | Description |
|------|-------------|
| 200 | Succès |
| 400 | Requête invalide (validation échouée) |
| 404 | Ressource non trouvée |
| 500 | Erreur serveur interne |

## 📝 Exemples d'utilisation

### JavaScript (Fetch API)

```javascript
// Envoyer un email
async function sendEmail(to, subject, body) {
  const response = await fetch('http://localhost:8000/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ to, subject, body })
  });
  
  return await response.json();
}

// Vérifier le statut
async function getEmailStatus(trackingId) {
  const response = await fetch(`http://localhost:8000/emails/${trackingId}`);
  return await response.json();
}

// Exemple d'utilisation
const email = await sendEmail(
  'user@example.com',
  'Test Email',
  '<h1>Hello World!</h1>'
);

console.log('Tracking ID:', email.tracking_id);

// Vérifier le statut après 5 secondes
setTimeout(async () => {
  const status = await getEmailStatus(email.tracking_id);
  console.log('Status:', status.status);
}, 5000);
```

### Python (requests)

```python
import requests
import time

# Envoyer un email
def send_email(to, subject, body):
    response = requests.post('http://localhost:8000/emails', json={
        'to': to,
        'subject': subject,
        'body': body
    })
    return response.json()

# Vérifier le statut
def get_email_status(tracking_id):
    response = requests.get(f'http://localhost:8000/emails/{tracking_id}')
    return response.json()

# Exemple d'utilisation
email = send_email('user@example.com', 'Test Email', '<h1>Hello World!</h1>')
print(f"Tracking ID: {email['tracking_id']}")

# Vérifier le statut après 5 secondes
time.sleep(5)
status = get_email_status(email['tracking_id'])
print(f"Status: {status['status']}")
```

### PHP (cURL)

```php
<?php
// Envoyer un email
function sendEmail($to, $subject, $body) {
    $data = json_encode([
        'to' => $to,
        'subject' => $subject,
        'body' => $body
    ]);
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/emails');
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    return json_decode($response, true);
}

// Vérifier le statut
function getEmailStatus($trackingId) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "http://localhost:8000/emails/{$trackingId}");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    return json_decode($response, true);
}

// Exemple d'utilisation
$email = sendEmail('user@example.com', 'Test Email', '<h1>Hello World!</h1>');
echo "Tracking ID: " . $email['tracking_id'] . "\n";

// Vérifier le statut après 5 secondes
sleep(5);
$status = getEmailStatus($email['tracking_id']);
echo "Status: " . $status['status'] . "\n";
?>
```

## 🚨 Gestion des Erreurs

### Erreurs de Validation

L'API valide automatiquement :
- **Format email** : Vérification de la validité de l'adresse email
- **Champs requis** : `to`, `subject`, `body` sont obligatoires
- **Champs non vides** : Les champs ne peuvent pas être vides ou contenir uniquement des espaces

### Erreurs de Serveur

- **500** : Erreur interne du serveur (problème de base de données, queue, etc.)
- **404** : Email non trouvé (ID de suivi invalide)

### Bonnes Pratiques

1. **Toujours vérifier les codes de statut HTTP**
2. **Gérer les erreurs de validation côté client**
3. **Implémenter un système de retry pour les erreurs temporaires**
4. **Utiliser les IDs de suivi pour le debugging**

## 🔧 Configuration Avancée

### Variables d'Environnement

```env
# Base de données MongoDB
MONGODB_URL=mongodb://mongodb:27017
MONGODB_DB=email_api

# Queue de messages RabbitMQ
MESSENGER_TRANSPORT_DSN=amqp://guest:guest@rabbitmq:5672/%2f/emails

# Configuration SMTP
MAILER_DSN=smtp://mailpit:1025

# Configuration de l'application
APP_ENV=dev
APP_DEBUG=true
```

### Limites et Quotas

Actuellement, l'API n'impose pas de limites de taux. Pour un usage en production, il est recommandé d'ajouter :
- Rate limiting (ex: 100 emails/minute par IP)
- Quotas par utilisateur
- Validation de la taille des emails

#!/bin/bash

# Chemin de base pour créer les fichiers
BASE_PATH="/home/yassmine/Desktop/api-email-async/skeleton"

# Création des répertoires nécessaires s'ils n'existent pas
mkdir -p $BASE_PATH/src/Document
mkdir -p $BASE_PATH/src/Message
mkdir -p $BASE_PATH/src/MessageHandler
mkdir -p $BASE_PATH/src/Controller
mkdir -p $BASE_PATH/src/Repository

echo "Création des fichiers pour l'API Email Asynchrone..."

# 1. Création du Document Email pour MongoDB
cat > $BASE_PATH/src/Document/Email.php << 'EOF'
<?php

namespace App\Document;

use Doctrine\ODM\MongoDB\Mapping\Annotations as MongoDB;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * @MongoDB\Document(repositoryClass="App\Repository\EmailRepository")
 */
class Email
{
    /**
     * @MongoDB\Id
     */
    private $id;

    /**
     * @MongoDB\Field(type="string")
     * @Assert\NotBlank
     * @Assert\Email
     */
    private $to;

    /**
     * @MongoDB\Field(type="string")
     * @Assert\NotBlank
     */
    private $subject;

    /**
     * @MongoDB\Field(type="string")
     * @Assert\NotBlank
     */
    private $body;

    /**
     * @MongoDB\Field(type="string")
     */
    private $status = 'queued';

    /**
     * @MongoDB\Field(type="date")
     */
    private $createdAt;

    /**
     * @MongoDB\Field(type="date", nullable=true)
     */
    private $sentAt;

    public function __construct()
    {
        $this->createdAt = new \DateTime();
    }

    public function getId()
    {
        return $this->id;
    }

    public function getTo()
    {
        return $this->to;
    }

    public function setTo($to)
    {
        $this->to = $to;
        return $this;
    }

    public function getSubject()
    {
        return $this->subject;
    }

    public function setSubject($subject)
    {
        $this->subject = $subject;
        return $this;
    }

    public function getBody()
    {
        return $this->body;
    }

    public function setBody($body)
    {
        $this->body = $body;
        return $this;
    }

    public function getStatus()
    {
        return $this->status;
    }

    public function setStatus($status)
    {
        $this->status = $status;
        return $this;
    }

    public function getCreatedAt()
    {
        return $this->createdAt;
    }

    public function getSentAt()
    {
        return $this->sentAt;
    }

    public function setSentAt(\DateTime $sentAt = null)
    {
        $this->sentAt = $sentAt;
        return $this;
    }
}
EOF

# 2. Création du Repository Email
cat > $BASE_PATH/src/Repository/EmailRepository.php << 'EOF'
<?php

namespace App\Repository;

use App\Document\Email;
use Doctrine\ODM\MongoDB\Repository\DocumentRepository;

class EmailRepository extends DocumentRepository
{
    public function findOneById(string $id): ?Email
    {
        return $this->find($id);
    }
}
EOF

# 3. Création du Message pour RabbitMQ
cat > $BASE_PATH/src/Message/SendEmailMessage.php << 'EOF'
<?php

namespace App\Message;

class SendEmailMessage
{
    private $emailId;

    public function __construct(string $emailId)
    {
        $this->emailId = $emailId;
    }

    public function getEmailId(): string
    {
        return $this->emailId;
    }
}
EOF

# 4. Création du MessageHandler
cat > $BASE_PATH/src/MessageHandler/SendEmailMessageHandler.php << 'EOF'
<?php

namespace App\MessageHandler;

use App\Document\Email;
use App\Message\SendEmailMessage;
use Doctrine\ODM\MongoDB\DocumentManager;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Messenger\Handler\MessageHandlerInterface;
use Symfony\Component\Mime\Email as SymfonyEmail;
use Psr\Log\LoggerInterface;

class SendEmailMessageHandler implements MessageHandlerInterface
{
    private $documentManager;
    private $mailer;
    private $logger;

    public function __construct(
        DocumentManager $documentManager,
        MailerInterface $mailer,
        LoggerInterface $logger
    ) {
        $this->documentManager = $documentManager;
        $this->mailer = $mailer;
        $this->logger = $logger;
    }

    public function __invoke(SendEmailMessage $message)
    {
        $emailId = $message->getEmailId();
        $this->logger->info('Processing email', ['id' => $emailId]);
        
        /** @var Email|null $email */
        $email = $this->documentManager->getRepository(Email::class)->findOneById($emailId);
        
        if (!$email) {
            $this->logger->error('Email not found', ['id' => $emailId]);
            return;
        }

        try {
            $symfonyEmail = (new SymfonyEmail())
                ->to($email->getTo())
                ->subject($email->getSubject())
                ->html($email->getBody());
            
            $this->mailer->send($symfonyEmail);
            
            $email->setStatus('sent');
            $email->setSentAt(new \DateTime());
            
            $this->documentManager->flush();
            $this->logger->info('Email sent successfully', ['id' => $emailId]);
        } catch (\Exception $e) {
            $email->setStatus('error');
            $this->documentManager->flush();
            
            $this->logger->error('Failed to send email', [
                'id' => $emailId,
                'error' => $e->getMessage()
            ]);
        }
    }
}
EOF

# 5. Création du Controller pour les endpoints
cat > $BASE_PATH/src/Controller/EmailController.php << 'EOF'
<?php

namespace App\Controller;

use App\Document\Email;
use App\Message\SendEmailMessage;
use Doctrine\ODM\MongoDB\DocumentManager;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

class EmailController extends AbstractController
{
    /**
     * @Route("/emails", name="create_email", methods={"POST"})
     */
    public function createEmail(
        Request $request, 
        DocumentManager $documentManager, 
        MessageBusInterface $messageBus,
        ValidatorInterface $validator
    ): JsonResponse {
        $data = json_decode($request->getContent(), true);

        if (!$data || !isset($data['to']) || !isset($data['subject']) || !isset($data['body'])) {
            return $this->json([
                'status' => 'error',
                'message' => 'Invalid request data. Required fields: to, subject, body'
            ], Response::HTTP_BAD_REQUEST);
        }

        $email = new Email();
        $email->setTo($data['to'])
              ->setSubject($data['subject'])
              ->setBody($data['body'])
              ->setStatus('queued');

        // Validation
        $errors = $validator->validate($email);
        if (count($errors) > 0) {
            $errorMessages = [];
            foreach ($errors as $error) {
                $errorMessages[$error->getPropertyPath()] = $error->getMessage();
            }
            
            return $this->json([
                'status' => 'error',
                'message' => 'Validation failed',
                'errors' => $errorMessages
            ], Response::HTTP_BAD_REQUEST);
        }

        $documentManager->persist($email);
        $documentManager->flush();

        // Dispatch message to RabbitMQ
        $messageBus->dispatch(new SendEmailMessage($email->getId()));

        return $this->json([
            'status' => 'success',
            'message' => 'Email queued successfully',
            'id' => $email->getId()
        ], Response::HTTP_CREATED);
    }

    /**
     * @Route("/emails/{id}", name="get_email_status", methods={"GET"})
     */
    public function getEmailStatus(string $id, DocumentManager $documentManager): JsonResponse
    {
        $email = $documentManager->getRepository(Email::class)->findOneById($id);

        if (!$email) {
            return $this->json([
                'status' => 'error',
                'message' => 'Email not found'
            ], Response::HTTP_NOT_FOUND);
        }

        return $this->json([
            'id' => $email->getId(),
            'to' => $email->getTo(),
            'subject' => $email->getSubject(),
            'status' => $email->getStatus(),
            'created_at' => $email->getCreatedAt()->format('Y-m-d H:i:s'),
            'sent_at' => $email->getSentAt() ? $email->getSentAt()->format('Y-m-d H:i:s') : null
        ]);
    }
}
EOF

# 6. Configuration pour Symfony Messenger (si besoin)
mkdir -p $BASE_PATH/config/packages
cat > $BASE_PATH/config/packages/messenger.yaml << 'EOF'
framework:
    messenger:
        # Uncomment this (and the failed transport below) to send failed messages to this transport for later handling.
        # failure_transport: failed

        transports:
            # https://symfony.com/doc/current/messenger.html#transport-configuration
            async_email:
                dsn: '%env(MESSENGER_TRANSPORT_DSN)%'
                retry_strategy:
                    max_retries: 3
                    multiplier: 2
            # failed: 'doctrine://default?queue_name=failed'

        routing:
            # Route your messages to the transports
            'App\Message\SendEmailMessage': async_email
EOF

# Définir les permissions appropriées
chmod -R 755 $BASE_PATH
find $BASE_PATH -type f -exec chmod 644 {} \;

echo "Création des fichiers terminée avec succès!"
echo "Pour utiliser l'API, assurez-vous que:"
echo "1. MongoDB est configuré correctement"
echo "2. RabbitMQ est installé et configuré"
echo "3. La variable MESSENGER_TRANSPORT_DSN est définie dans votre .env (ex: amqp://guest:guest@localhost:5672/%2f/messages)"
echo "4. Le mailer est configuré dans votre .env (ex: MAILER_DSN=smtp://localhost:1025)"
echo ""
echo "Les endpoints suivants sont disponibles:"
echo "POST /emails - Pour créer un nouvel email"
echo "GET /emails/{id} - Pour vérifier le statut d'un email"

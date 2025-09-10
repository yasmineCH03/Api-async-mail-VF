<?php

namespace App\MessageHandler;

use App\Document\Email;
use App\Message\SendEmailMessage;
use Doctrine\ODM\MongoDB\DocumentManager;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Messenger\Handler\MessageHandlerInterface;
use Symfony\Component\Mime\Email as MimeEmail;

class SendEmailMessageHandler implements MessageHandlerInterface
{
    private $mailer;
    private $documentManager;

    public function __construct(MailerInterface $mailer, DocumentManager $documentManager)
    {
        $this->mailer = $mailer;
        $this->documentManager = $documentManager;
    }

    public function __invoke(SendEmailMessage $message)
    {
        try {
            $email = (new MimeEmail())
                ->from('your-app@example.com')
                ->to($message->getTo())
                ->subject($message->getSubject())
                ->html($message->getBody());

            $this->mailer->send($email);

            // Update email status to sent in MongoDB
            $emailDocument = $this->documentManager->getRepository(Email::class)
                ->findOneBy([
                    'trackingId' => $message->getTrackingId(),
                    'status' => 'queued'
                ]);

            if ($emailDocument) {
                $emailDocument->setStatus('sent');
                $this->documentManager->flush();
            }
        } catch (\Exception $e) {
            // Update email status to failed in MongoDB
            $emailDocument = $this->documentManager->getRepository(Email::class)
                ->findOneBy([
                    'trackingId' => $message->getTrackingId(),
                    'status' => 'queued'
                ]);

            if ($emailDocument) {
                $emailDocument->setStatus('failed');
                $this->documentManager->flush();
            }

            throw $e;
        }
    }
}
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

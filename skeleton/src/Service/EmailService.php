<?php
namespace App\Service;

use App\Document\Email;
use App\Message\SendEmailMessage;
use Doctrine\ODM\MongoDB\DocumentManager;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\Mime\Email as MimeEmail;

class EmailService
{
    private $mailer;
    private $queueDir;
    private $messageBus;
    private $documentManager;

    public function __construct(MailerInterface $mailer, string $projectDir, MessageBusInterface $messageBus, DocumentManager $documentManager)
    {
        $this->mailer = $mailer;
        $this->queueDir = $projectDir . '/var/queue';
        $this->messageBus = $messageBus;
        $this->documentManager = $documentManager;

        // Create queue directory if it doesn't exist
        if (!is_dir($this->queueDir)) {
            mkdir($this->queueDir, 0777, true);
        }
    }

    public function queueEmail(string $to, string $subject, string $body): string
    {
        // Generate unique tracking ID
        $trackingId = uniqid('email_', true);
        
        // Create and save email document to MongoDB
        $emailDocument = new Email();
        $emailDocument->setTrackingId($trackingId);
        $emailDocument->setTo($to);
        $emailDocument->setSubject($subject);
        $emailDocument->setBody($body);
        $emailDocument->setStatus('queued');

        $this->documentManager->persist($emailDocument);
        $this->documentManager->flush();

        // Using Symfony Messenger for async processing
        $this->messageBus->dispatch(new SendEmailMessage($to, $subject, $body, $trackingId));

        // Keep backup in file system as well
        $emailData = [
            'tracking_id' => $trackingId,
            'to' => $to,
            'subject' => $subject,
            'body' => $body,
            'created_at' => (new \DateTime())->format('Y-m-d H:i:s'),
        ];

        $filename = $this->queueDir . '/' . $trackingId . '.json';
        file_put_contents($filename, json_encode($emailData));
        
        return $trackingId;
    }

    public function processQueue(): void
    {
        $files = glob($this->queueDir . '/*.json');

        foreach ($files as $file) {
            if (!file_exists($file)) {
                continue;
            }

            $emailData = json_decode(file_get_contents($file), true);

            $email = (new MimeEmail())
                ->from('your-app@example.com')
                ->to($emailData['to'])
                ->subject($emailData['subject'])
                ->html($emailData['body']);

            try {
                $this->mailer->send($email);
                unlink($file);  // Remove the file after sending
            } catch (\Exception $e) {
                // Log error and keep file for retry
                error_log('Failed to send email: ' . $e->getMessage());
            }
        }
    }
}
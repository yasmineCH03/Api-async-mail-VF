<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use App\Service\EmailService;
use App\Document\Email;
use Doctrine\ODM\MongoDB\DocumentManager;

class EmailController extends AbstractController
{
    private $emailService;
    private $documentManager;

    public function __construct(EmailService $emailService, DocumentManager $documentManager)
    {
        $this->emailService = $emailService;
        $this->documentManager = $documentManager;
    }

    #[Route('/emails', name: 'send_email', methods: ['POST'])]
    public function sendEmail(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        // Validate required fields
        if (!isset($data['to']) || !isset($data['subject']) || !isset($data['body'])) {
            return $this->json(['error' => 'Missing required parameters: to, subject, body'], 400);
        }

        // Validate email format
        if (!filter_var($data['to'], FILTER_VALIDATE_EMAIL)) {
            return $this->json(['error' => 'Invalid email address'], 400);
        }

        // Validate empty fields
        if (empty(trim($data['subject']))) {
            return $this->json(['error' => 'Subject cannot be empty'], 400);
        }

        if (empty(trim($data['body']))) {
            return $this->json(['error' => 'Body cannot be empty'], 400);
        }

        try {
            $trackingId = $this->emailService->queueEmail($data['to'], $data['subject'], $data['body']);
            return $this->json([
                'message' => 'Email queued successfully',
                'tracking_id' => $trackingId
            ]);
        } catch (\Exception $e) {
            return $this->json(['error' => $e->getMessage()], 500);
        }
    }

    #[Route('/emails/{id}', name: 'get_email_status', methods: ['GET'])]
    public function getEmailStatus(string $id): JsonResponse
    {
        try {
            $email = $this->documentManager->getRepository(Email::class)
                ->findOneBy(['trackingId' => $id]);

            if (!$email) {
                return $this->json(['error' => 'Email not found'], 404);
            }

            return $this->json([
                'tracking_id' => $email->getTrackingId(),
                'to' => $email->getTo(),
                'subject' => $email->getSubject(),
                'status' => $email->getStatus(),
                'created_at' => $email->getCreatedAt()->format('Y-m-d H:i:s')
            ]);
        } catch (\Exception $e) {
            return $this->json(['error' => $e->getMessage()], 500);
        }
    }
}
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

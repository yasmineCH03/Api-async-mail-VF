<?php

namespace App\Message;

class SendEmailMessage
{
    private $to;
    private $subject;
    private $body;
    private $trackingId;

    public function __construct(string $to, string $subject, string $body, string $trackingId)
    {
        $this->to = $to;
        $this->subject = $subject;
        $this->body = $body;
        $this->trackingId = $trackingId;
    }

    public function getTo(): string
    {
        return $this->to;
    }

    public function getSubject(): string
    {
        return $this->subject;
    }

    public function getBody(): string
    {
        return $this->body;
    }

    public function getTrackingId(): string
    {
        return $this->trackingId;
    }
}
<?php

namespace App\Document;

use Doctrine\ODM\MongoDB\Mapping\Annotations as MongoDB;

#[MongoDB\Document]
class Email
{
    #[MongoDB\Id]
    private ?string $id = null;

    #[MongoDB\Field(type: 'string')]
    private ?string $trackingId = null;

    #[MongoDB\Field(type: 'string')]
    private ?string $to = null;

    #[MongoDB\Field(type: 'string')]
    private ?string $subject = null;

    #[MongoDB\Field(type: 'string')]
    private ?string $body = null;

    #[MongoDB\Field(type: 'string')]
    private ?string $status = 'queued';

    #[MongoDB\Field(type: 'date')]
    private ?\DateTime $createdAt = null;

    public function __construct()
    {
        $this->createdAt = new \DateTime();
    }

    // Getters and setters
    public function getId(): ?string
    {
        return $this->id;
    }

    public function getTrackingId(): ?string
    {
        return $this->trackingId;
    }

    public function setTrackingId(string $trackingId): self
    {
        $this->trackingId = $trackingId;
        return $this;
    }

    public function getTo(): ?string
    {
        return $this->to;
    }

    public function setTo(string $to): self
    {
        $this->to = $to;
        return $this;
    }

    public function getSubject(): ?string
    {
        return $this->subject;
    }

    public function setSubject(string $subject): self
    {
        $this->subject = $subject;
        return $this;
    }

    public function getBody(): ?string
    {
        return $this->body;
    }

    public function setBody(string $body): self
    {
        $this->body = $body;
        return $this;
    }

    public function getStatus(): ?string
    {
        return $this->status;
    }

    public function setStatus(string $status): self
    {
        $this->status = $status;
        return $this;
    }

    public function getCreatedAt(): ?\DateTime
    {
        return $this->createdAt;
    }
}
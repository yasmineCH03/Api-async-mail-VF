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

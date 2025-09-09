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

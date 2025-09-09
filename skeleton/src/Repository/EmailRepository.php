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

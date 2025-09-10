<?php

namespace App\Command;

use App\Service\EmailService;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class ProcessEmailQueueCommand extends Command
{
    protected static $defaultName = 'app:process-email-queue';
    private $emailService;

    public function __construct(EmailService $emailService)
    {
        $this->emailService = $emailService;
        parent::__construct();
    }

    protected function configure()
    {
        $this->setDescription('Process queued emails');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $output->writeln('Processing email queue...');
        $this->emailService->processQueue();
        $output->writeln('Done!');

        return Command::SUCCESS;
    }
}
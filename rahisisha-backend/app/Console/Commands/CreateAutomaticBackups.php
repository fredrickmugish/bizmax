<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\BackupService;
use Illuminate\Console\Command;

class CreateAutomaticBackups extends Command
{
    protected $signature = 'backups:create-automatic';
    protected $description = 'Create automatic backups for all users';

    protected $backupService;

    public function __construct(BackupService $backupService)
    {
        parent::__construct();
        $this->backupService = $backupService;
    }

    public function handle()
    {
        $this->info('Starting automatic backup creation...');

        $users = User::all();
        $successCount = 0;
        $failureCount = 0;

        foreach ($users as $user) {
            try {
                $this->backupService->scheduleAutomaticBackup($user);
                $this->info("Backup created for user: {$user->name}");
                $successCount++;
            } catch (\Exception $e) {
                $this->error("Failed to create backup for user {$user->name}: {$e->getMessage()}");
                $failureCount++;
            }
        }

        $this->info("Automatic backup creation completed.");
        $this->info("Successful: {$successCount}, Failed: {$failureCount}");

        return Command::SUCCESS;
    }
}

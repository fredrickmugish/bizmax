<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\BackupService;
use Illuminate\Console\Command;

class CleanupOldBackups extends Command
{
    protected $signature = 'backups:cleanup {--days=30 : Number of days to keep backups}';
    protected $description = 'Clean up old backup files';

    protected $backupService;

    public function __construct(BackupService $backupService)
    {
        parent::__construct();
        $this->backupService = $backupService;
    }

    public function handle()
    {
        $keepDays = (int) $this->option('days');
        $this->info("Cleaning up backups older than {$keepDays} days...");

        $users = User::all();
        $totalCleaned = 0;

        foreach ($users as $user) {
            try {
                $cleaned = $this->backupService->cleanupOldBackups($user, $keepDays);
                $totalCleaned += $cleaned;
                
                if ($cleaned > 0) {
                    $this->info("Cleaned {$cleaned} old backups for user: {$user->name}");
                }
            } catch (\Exception $e) {
                $this->error("Failed to cleanup backups for user {$user->name}: {$e->getMessage()}");
            }
        }

        $this->info("Cleanup completed. Total backups cleaned: {$totalCleaned}");

        return Command::SUCCESS;
    }
}

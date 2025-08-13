<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Create automatic backups daily at 2 AM
        $schedule->command('backups:create-automatic')
                 ->dailyAt('02:00')
                 ->withoutOverlapping();

        // Clean up old backups weekly
        $schedule->command('backups:cleanup --days=30')
                 ->weekly()
                 ->sundays()
                 ->at('03:00');

        // Generate low stock notifications daily at 9 AM
        $schedule->call(function () {
            \App\Models\User::chunk(100, function ($users) {
                foreach ($users as $user) {
                    $lowStockItems = $user->inventoryItems()->active()->lowStock()->count();
                    
                    if ($lowStockItems > 0) {
                        // Check if we already have a recent notification
                        $recentNotification = $user->notifications()
                            ->where('type', 'low_stock')
                            ->where('created_at', '>=', now()->subHours(24))
                            ->first();

                        if (!$recentNotification) {
                            $user->notifications()->create([
                                'title' => 'Hifadhi Chini',
                                'message' => "Bidhaa {$lowStockItems} zina hifadhi chini ya kiwango cha chini",
                                'type' => 'low_stock',
                                'data' => ['items_count' => $lowStockItems],
                                'action_url' => '/inventory?filter=low_stock',
                            ]);
                        }
                    }
                }
            });
        })->dailyAt('09:00');
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}

<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;

class SyncUserBusinessFields extends Command
{
    protected $signature = 'users:sync-business-fields';
    protected $description = 'Sync business_id and role fields in users table with the first business in business_user pivot table';

    public function handle()
    {
        $users = User::all();
        $count = 0;
        foreach ($users as $user) {
            $pivot = $user->businesses()->first();
            if ($pivot) {
                $user->business_id = $pivot->id;
                $user->role = $pivot->pivot->role;
                $user->save();
                $count++;
            }
        }
        $this->info("Updated $count users.");
    }
} 
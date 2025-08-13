<?php

namespace App\Services;

use App\Models\Backup;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class BackupService
{
    public function createBackup(User $user, array $dataTypes, string $backupType = 'manual')
    {
        $filename = $this->generateBackupFilename($user, $backupType);
        $filePath = "backups/{$user->id}/{$filename}";

        // Create backup record
        $backup = $user->backups()->create([
            'filename' => $filename,
            'file_path' => $filePath,
            'backup_type' => $backupType,
            'status' => 'pending',
            'data_types' => $dataTypes,
        ]);

        try {
            // Collect data based on requested types
            $backupData = [
                'user_info' => [
                    'name' => $user->name,
                    'business_name' => $user->business_name,
                    'business_type' => $user->business_type,
                    'created_at' => $user->created_at,
                ],
                'backup_info' => [
                    'created_at' => now(),
                    'version' => '1.0',
                    'data_types' => $dataTypes,
                ],
                'data' => []
            ];

            if (in_array('inventory', $dataTypes)) {
                $backupData['data']['inventory'] = $user->inventoryItems()
                    ->with('stockMovements')
                    ->get()
                    ->toArray();
            }

            if (in_array('records', $dataTypes)) {
                $backupData['data']['business_records'] = $user->businessRecords()
                    ->with('payments')
                    ->get()
                    ->toArray();
            }

            if (in_array('settings', $dataTypes)) {
                $backupData['data']['settings'] = [
                    'business_name' => $user->business_name,
                    'business_type' => $user->business_type,
                    'business_address' => $user->business_address,
                    'phone' => $user->phone,
                    'language' => $user->language,
                    'currency' => $user->currency,
                    'timezone' => $user->timezone,
                ];
            }

            // Convert to JSON and save
            $jsonData = json_encode($backupData, JSON_PRETTY_PRINT);
            Storage::put($filePath, $jsonData);

            // Update backup record
            $backup->update([
                'status' => 'completed',
                'file_size' => Storage::size($filePath),
                'completed_at' => now(),
            ]);

            return $backup;

        } catch (\Exception $e) {
            $backup->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    public function restoreFromFile(User $user, UploadedFile $file)
    {
        $content = file_get_contents($file->getRealPath());
        $backupData = json_decode($content, true);

        if (!$backupData || !isset($backupData['data'])) {
            throw new \Exception('Invalid backup file format');
        }

        DB::beginTransaction();
        try {
            $restored = [];

            // Restore inventory items
            if (isset($backupData['data']['inventory'])) {
                $this->restoreInventory($user, $backupData['data']['inventory']);
                $restored[] = 'inventory';
            }

            // Restore business records
            if (isset($backupData['data']['business_records'])) {
                $this->restoreBusinessRecords($user, $backupData['data']['business_records']);
                $restored[] = 'business_records';
            }

            // Restore settings
            if (isset($backupData['data']['settings'])) {
                $this->restoreSettings($user, $backupData['data']['settings']);
                $restored[] = 'settings';
            }

            DB::commit();

            return [
                'restored_data_types' => $restored,
                'restored_at' => now(),
            ];

        } catch (\Exception $e) {
            DB::rollback();
            throw $e;
        }
    }

    private function restoreInventory(User $user, array $inventoryData)
    {
        foreach ($inventoryData as $itemData) {
            // Remove timestamps and relations
            $cleanData = collect($itemData)->except([
                'id', 'user_id', 'created_at', 'updated_at', 'stock_movements'
            ])->toArray();

            $cleanData['user_id'] = $user->id;

            // Check if item already exists by name
            $existingItem = $user->inventoryItems()
                ->where('name', $cleanData['name'])
                ->first();

            if ($existingItem) {
                $existingItem->update($cleanData);
                $item = $existingItem;
            } else {
                $item = $user->inventoryItems()->create($cleanData);
            }

            // Restore stock movements if available
            if (isset($itemData['stock_movements'])) {
                foreach ($itemData['stock_movements'] as $movementData) {
                    $cleanMovementData = collect($movementData)->except([
                        'id', 'inventory_item_id', 'user_id', 'created_at', 'updated_at'
                    ])->toArray();

                    $cleanMovementData['user_id'] = $user->id;
                    $item->stockMovements()->create($cleanMovementData);
                }
            }
        }
    }

    private function restoreBusinessRecords(User $user, array $recordsData)
    {
        foreach ($recordsData as $recordData) {
            // Remove timestamps and relations
            $cleanData = collect($recordData)->except([
                'id', 'user_id', 'created_at', 'updated_at', 'payments'
            ])->toArray();

            $cleanData['user_id'] = $user->id;

            // Check if record already exists by description and date
            $existingRecord = $user->businessRecords()
                ->where('description', $cleanData['description'])
                ->where('date', $cleanData['date'])
                ->where('amount', $cleanData['amount'])
                ->first();

            if (!$existingRecord) {
                $record = $user->businessRecords()->create($cleanData);

                // Restore payments if available
                if (isset($recordData['payments'])) {
                    foreach ($recordData['payments'] as $paymentData) {
                        $cleanPaymentData = collect($paymentData)->except([
                            'id', 'business_record_id', 'created_at', 'updated_at'
                        ])->toArray();

                        $record->payments()->create($cleanPaymentData);
                    }
                }
            }
        }
    }

    private function restoreSettings(User $user, array $settingsData)
    {
        $user->update($settingsData);
    }

    private function generateBackupFilename(User $user, string $backupType)
    {
        $timestamp = now()->format('Y-m-d_H-i-s');
        $businessName = str_replace(' ', '_', $user->business_name ?? 'business');
        
        return "{$businessName}_{$backupType}_backup_{$timestamp}.json";
    }

    public function scheduleAutomaticBackup(User $user)
    {
        // This would be called by a scheduled job
        return $this->createBackup($user, ['inventory', 'records', 'settings'], 'automatic');
    }

    public function cleanupOldBackups(User $user, int $keepDays = 30)
    {
        $oldBackups = $user->backups()
            ->where('created_at', '<', now()->subDays($keepDays))
            ->get();

        foreach ($oldBackups as $backup) {
            if (Storage::exists($backup->file_path)) {
                Storage::delete($backup->file_path);
            }
            $backup->delete();
        }

        return $oldBackups->count();
    }
}

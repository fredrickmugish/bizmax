<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Backup;
use App\Services\BackupService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class BackupController extends Controller
{
    protected $backupService;

    public function __construct(BackupService $backupService)
    {
        $this->backupService = $backupService;
    }

    public function index()
    {
        $backups = auth()->user()->backups()
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        return response()->json([
            'success' => true,
            'data' => $backups
        ]);
    }

    public function create(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'data_types' => 'required|array',
            'data_types.*' => 'in:inventory,records,settings',
            'backup_type' => 'sometimes|in:manual,automatic',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $backup = $this->backupService->createBackup(
                auth()->user(),
                $request->data_types,
                $request->get('backup_type', 'manual')
            );

            return response()->json([
                'success' => true,
                'message' => 'Backup created successfully',
                'data' => $backup
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create backup: ' . $e->getMessage()
            ], 500);
        }
    }

    public function download($id)
    {
        $backup = auth()->user()->backups()->findOrFail($id);

        if ($backup->status !== 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Backup is not ready for download'
            ], 400);
        }

        if (!Storage::exists($backup->file_path)) {
            return response()->json([
                'success' => false,
                'message' => 'Backup file not found'
            ], 404);
        }

        return Storage::download($backup->file_path, $backup->filename);
    }

    public function restore(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'backup_file' => 'required|file|mimes:json|max:10240', // 10MB max
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $file = $request->file('backup_file');
            $result = $this->backupService->restoreFromFile(auth()->user(), $file);

            return response()->json([
                'success' => true,
                'message' => 'Data restored successfully',
                'data' => $result
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to restore backup: ' . $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id)
    {
        $backup = auth()->user()->backups()->findOrFail($id);

        try {
            // Delete file from storage
            if (Storage::exists($backup->file_path)) {
                Storage::delete($backup->file_path);
            }

            // Delete backup record
            $backup->delete();

            return response()->json([
                'success' => true,
                'message' => 'Backup deleted successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete backup: ' . $e->getMessage()
            ], 500);
        }
    }

    public function getBackupInfo()
    {
        $user = auth()->user();
        
        $info = [
            'total_backups' => $user->backups()->count(),
            'completed_backups' => $user->backups()->where('status', 'completed')->count(),
            'latest_backup' => $user->backups()->where('status', 'completed')->latest()->first(),
            'total_backup_size' => $user->backups()->where('status', 'completed')->sum('file_size'),
            'data_summary' => [
                'inventory_items' => $user->inventoryItems()->count(),
                'business_records' => $user->businessRecords()->count(),
                'notifications' => $user->notifications()->count(),
            ]
        ];

        return response()->json([
            'success' => true,
            'data' => $info
        ]);
    }
}

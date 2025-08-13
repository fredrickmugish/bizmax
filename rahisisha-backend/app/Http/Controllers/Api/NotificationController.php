<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $query = auth()->user()->notifications();

        // Filter by type
        if ($request->has('type') && $request->type) {
            $query->byType($request->type);
        }

        // Filter by read status
        if ($request->has('unread_only') && $request->unread_only) {
            $query->unread();
        }

        $notifications = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $notifications,
            'unread_count' => auth()->user()->notifications()->unread()->count()
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'required|in:low_stock,sales,debt,system,report',
            'data' => 'nullable|array',
            'action_url' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $notification = auth()->user()->notifications()->create($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Notification created successfully',
            'data' => $notification
        ], 201);
    }

    public function show($id)
    {
        $notification = auth()->user()->notifications()->findOrFail($id);

        // Mark as read when viewed
        if (!$notification->is_read) {
            $notification->markAsRead();
        }

        return response()->json([
            'success' => true,
            'data' => $notification
        ]);
    }

    public function markAsRead($id)
    {
        $notification = auth()->user()->notifications()->findOrFail($id);
        $notification->markAsRead();

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as read'
        ]);
    }

    public function markAllAsRead()
    {
        auth()->user()->notifications()->unread()->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read'
        ]);
    }

    public function destroy($id)
    {
        $notification = auth()->user()->notifications()->findOrFail($id);
        $notification->delete();

        return response()->json([
            'success' => true,
            'message' => 'Notification deleted successfully'
        ]);
    }

    public function destroyAll()
    {
        auth()->user()->notifications()->delete();

        return response()->json([
            'success' => true,
            'message' => 'All notifications deleted successfully'
        ]);
    }

    public function getUnreadCount()
    {
        $count = auth()->user()->notifications()->unread()->count();

        return response()->json([
            'success' => true,
            'data' => ['unread_count' => $count]
        ]);
    }

    public function generateLowStockNotifications()
    {
        $user = auth()->user();
        $lowStockItems = $user->inventoryItems()->active()->lowStock()->get();

        if ($lowStockItems->count() > 0) {
            // Check if we already have a recent low stock notification
            $recentNotification = $user->notifications()
                ->where('type', 'low_stock')
                ->where('created_at', '>=', now()->subHours(24))
                ->first();

            if (!$recentNotification) {
                $user->notifications()->create([
                    'title' => 'Hifadhi Chini',
                    'message' => "Bidhaa {$lowStockItems->count()} zina hifadhi chini ya kiwango cha chini",
                    'type' => 'low_stock',
                    'data' => [
                        'items_count' => $lowStockItems->count(),
                        'items' => $lowStockItems->pluck('name')->toArray()
                    ],
                    'action_url' => '/inventory?filter=low_stock',
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Low stock notifications generated',
            'items_count' => $lowStockItems->count()
        ]);
    }
}

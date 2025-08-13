<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\InventoryController;
use App\Http\Controllers\Api\BusinessRecordController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\BackupController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\UserManagementController;
use App\Http\Middleware\CheckRole;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::post('register', [AuthController::class, 'register']);
Route::post('login', [AuthController::class, 'login']);
Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('reset-password', [AuthController::class, 'resetPassword']);

// Protected routes - All routes within this group require a valid access token
Route::middleware('auth:api')->group(function () {

    // Authentication routes (except login/register/refresh)
    Route::prefix('auth')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
    });

    // Dashboard routes
    Route::prefix('dashboard')->group(function () {
        Route::get('/', [DashboardController::class, 'index']);
        Route::get('metrics', [DashboardController::class, 'businessMetrics']);
        Route::get('health', [DashboardController::class, 'businessHealth']);
        Route::get('sales-trends', [DashboardController::class, 'salesTrends']);
        Route::get('top-products', [DashboardController::class, 'topProducts']);
        Route::get('expense-breakdown', [DashboardController::class, 'expenseBreakdown']);
        Route::get('recent-activities', [DashboardController::class, 'recentActivities']);
        Route::get('summary', [DashboardController::class, 'getDashboardSummary']);
    });

    // Inventory routes (Owner/Admin/Salesperson depending on your rules)
    Route::prefix('inventory')->group(function () {
        Route::get('/', [InventoryController::class, 'index']);
        Route::post('/', [InventoryController::class, 'store']);
        Route::get('categories', [InventoryController::class, 'categories']);
        Route::get('low-stock', [InventoryController::class, 'lowStock']);

        Route::prefix('{id}')->group(function () {
            Route::get('/', [InventoryController::class, 'show']);
            Route::put('/', [InventoryController::class, 'update']);
            Route::delete('/', [InventoryController::class, 'destroy']);
            Route::post('update-stock', [InventoryController::class, 'updateStock']);
            Route::post('adjust-stock', [InventoryController::class, 'adjustStock']);
            Route::get('stock-movements', [InventoryController::class, 'stockMovements']);
        });
    });

    // Business records routes (Owner/Admin/Salesperson)
    Route::prefix('records')->group(function () {
        Route::get('/', [BusinessRecordController::class, 'index']);
        Route::post('/', [BusinessRecordController::class, 'store']);
        Route::get('credit-sales', [BusinessRecordController::class, 'creditSales']);
        Route::get('by-transaction/{transactionId}', [BusinessRecordController::class, 'getRecordsByTransactionId']);

        Route::prefix('{id}')->group(function () {
            Route::get('/', [BusinessRecordController::class, 'show']);
            Route::put('/', [BusinessRecordController::class, 'update']);
            Route::delete('/', [BusinessRecordController::class, 'destroy']);
            Route::post('make-payment', [BusinessRecordController::class, 'makePayment']);
        });
    });

    // Notifications routes
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::post('/', [NotificationController::class, 'store']);
        Route::get('unread-count', [NotificationController::class, 'getUnreadCount']);
        Route::post('mark-all-read', [NotificationController::class, 'markAllAsRead']);
        Route::delete('all', [NotificationController::class, 'destroyAll']);
        Route::post('generate-low-stock', [NotificationController::class, 'generateLowStockNotifications']);

        Route::prefix('{id}')->group(function () {
            Route::get('/', [NotificationController::class, 'show']);
            Route::post('mark-read', [NotificationController::class, 'markAsRead']);
            Route::delete('/', [NotificationController::class, 'destroy']);
        });
    });

    // Backup routes (Likely Admin/Owner only)
    Route::middleware(CheckRole::class . ':admin,owner')->prefix('backups')->group(function () {
        Route::get('/', [BackupController::class, 'index']);
        Route::post('/', [BackupController::class, 'create']);
        Route::post('restore', [BackupController::class, 'restore']);
        Route::get('info', [BackupController::class, 'getBackupInfo']);

        Route::prefix('{id}')->group(function () {
            Route::get('download', [BackupController::class, 'download']);
            Route::delete('/', [BackupController::class, 'destroy']);
        });
    });

    // Quick actions routes (Owner/Admin/Salesperson)
    Route::prefix('quick')->group(function () {
        Route::post('sale', function (Request $request) {
            return app(BusinessRecordController::class)->store(
                $request->merge(['type' => 'sale'])
            );
        });

        Route::post('purchase', function (Request $request) {
            return app(BusinessRecordController::class)->store(
                $request->merge(['type' => 'purchase'])
            );
        });

        Route::post('expense', function (Request $request) {
            return app(BusinessRecordController::class)->store(
                $request->merge(['type' => 'expense'])
            );
        });
    });

    // Notes routes
    Route::apiResource('notes', \App\Http\Controllers\Api\NoteController::class);

    // Customers routes
    Route::apiResource('customers', CustomerController::class);

    // Reports routes (basic endpoints)
    Route::prefix('reports')->group(function () {
        Route::get('summary', function () {
            $user = auth()->user();
            $businessRecords = $user->businessRecords();
            $inventoryItems = $user->inventoryItems();

            if ($user->isSalesperson()) {
                $businessRecords = $businessRecords->where('user_id', $user->id);
                $inventoryItems = $inventoryItems->where('user_id', $user->id);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'total_sales' => $businessRecords->sales()->sum('amount'),
                    'total_purchases' => $businessRecords->purchases()->sum('amount'),
                    'total_expenses' => $businessRecords->expenses()->sum('amount'),
                    'total_profit' => $businessRecords->sales()->sum('amount') - $businessRecords->expenses()->sum('amount'),
                    'total_products' => $inventoryItems->active()->count(),
                    'low_stock_items' => $inventoryItems->active()->lowStock()->count(),
                    'total_debt' => $businessRecords->creditSales()->sum('debt_amount'),
                ]
            ]);
        });

        Route::get('sales', function (Request $request) {
            $user = auth()->user();
            $query = $user->businessRecords()->sales();

            if ($user->isSalesperson()) {
                $query = $query->where('user_id', $user->id);
            }

            if ($request->has('start_date') && $request->has('end_date')) {
                $query->byDateRange($request->start_date, $request->end_date);
            }

            return response()->json([
                'success' => true,
                'data' => $query->orderBy('date', 'desc')->paginate(20)
            ]);
        });

        Route::get('inventory-valuation', function () {
            $user = auth()->user();
            $items = $user->inventoryItems()->active()->get();

            $valuation = $items->map(function ($item) {
                return [
                    'name' => $item->name,
                    'category' => $item->category,
                    'current_stock' => $item->current_stock,
                    'buying_price' => $item->buying_price,
                    'selling_price' => $item->selling_price,
                    'stock_value' => $item->current_stock * $item->buying_price,
                    'potential_revenue' => $item->current_stock * $item->selling_price,
                    'potential_profit' => $item->current_stock * ($item->selling_price - $item->buying_price),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'items' => $valuation,
                    'summary' => [
                        'total_stock_value' => $valuation->sum('stock_value'),
                        'potential_revenue' => $valuation->sum('potential_revenue'),
                        'potential_profit' => $valuation->sum('potential_profit'),
                    ]
                ]
            ]);
        });
    });

    // User management routes (LIKELY ADMIN/OWNER ONLY)
    Route::prefix('users')->group(function () {
        Route::middleware(CheckRole::class . ':admin,owner')->group(function () {
            Route::get('/', [UserManagementController::class, 'index']);
            Route::post('/', [UserManagementController::class, 'store']);
            Route::delete('{id}', [UserManagementController::class, 'destroy']);
            Route::post('{id}/reset-password', [UserManagementController::class, 'resetPassword']);
        });
    });

    Route::post('/businesses', [App\Http\Controllers\Api\BusinessController::class, 'store']);
});

// Health check route
Route::get('health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now(),
        'version' => '1.0.0'
    ]);
});

// Fallback route for API
Route::fallback(function () {
    return response()->json([
        'success' => false,
        'message' => 'API endpoint not found'
    ], 404);
});
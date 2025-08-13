<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BusinessRecord;
use App\Models\InventoryItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function getDashboardSummary(Request $request)
    {
        $user = auth()->user();

        // Fetch all necessary data in parallel or sequentially as needed
        $businessMetrics = $this->businessMetrics($request)->getData(true)['data'];
        $businessHealth = $this->businessHealth($request)->getData(true)['data'];
        $salesTrends = $this->salesTrends($request)->getData(true)['data'];
        $topProducts = $this->topProducts($request)->getData(true)['data'];
        $recentActivities = $this->recentActivities($request)->getData(true)['data'];
        $lowStockAlerts = $this->getLowStockAlerts($user);
        $quickStats = $this->getQuickStats($user);

        // Additional data not covered by existing dashboard endpoints
        $totalInventoryItems = InventoryItem::where('business_id', $user->business_id)->count();
        $totalBusinessRecords = BusinessRecord::where('business_id', $user->business_id)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'business_metrics' => $businessMetrics,
                'business_health' => $businessHealth,
                'sales_trends' => $salesTrends,
                'top_products' => $topProducts,
                'recent_activities' => $recentActivities,
                'low_stock_alerts' => $lowStockAlerts,
                'quick_stats' => $quickStats,
                'total_inventory_items' => $totalInventoryItems,
                'total_business_records' => $totalBusinessRecords,
                'user_name' => $user->name,
                'business_name' => $user->business->name,
                'business_address' => $user->business->address,
                'phone' => $user->phone,
            ]
        ]);
    }

    public function index(Request $request)
    {
        // This method can now simply call the summary or be repurposed
        // For now, let's keep it as is, but the Flutter app will use the new summary endpoint
        $user = auth()->user();
        
        return response()->json([
            'success' => true,
            'data' => [
                'business_metrics' => $this->getBusinessMetrics($user),
                'business_health' => $this->getBusinessHealth($user),
                'recent_activities' => $this->getRecentActivities($user),
                'low_stock_alerts' => $this->getLowStockAlerts($user),
                'quick_stats' => $this->getQuickStats($user),
            ]
        ]);
    }

    public function businessMetrics(Request $request)
    {
        $user = auth()->user();
        $period = $request->get('period', 'month'); // day, week, month, year

        $startDate = $this->getStartDate($period);
        $endDate = now();

        // Get all records for the period using business-based filtering
        $periodQuery = BusinessRecord::where('business_id', $user->business_id)
            ->byDateRange($startDate, $endDate);
            
        // If salesperson, only show their own records
        if ($user->role === 'salesperson') {
            $periodQuery->where('user_id', $user->id);
        }
        
        $periodRecords = $periodQuery->with('product')->get();

        // Calculate accurate profit metrics
        $salesRecords = $periodRecords->where('type', 'sale');
        $purchaseRecords = $periodRecords->where('type', 'purchase');
        $expenseRecords = $periodRecords->where('type', 'expense');

        // Only include profit from cash sales and fully paid credit sales
        $allSalesQuery = BusinessRecord::where('business_id', $user->business_id)->sales();
        $todaySalesQuery = BusinessRecord::where('business_id', $user->business_id)->sales()->today();
        
        // If salesperson, filter to only their records
        if ($user->role === 'salesperson') {
            $allSalesQuery->where('user_id', $user->id);
            $todaySalesQuery->where('user_id', $user->id);
        }
        
        $allSales = $allSalesQuery->with('product')->get();
        $fullyPaidSales = $allSales->filter(function ($record) {
            return !$record->is_credit || $record->is_paid_in_full;
        });
        $periodFullyPaidSales = $salesRecords->filter(function ($record) {
            return !$record->is_credit || $record->is_paid_in_full;
        });
        $todaySales = $todaySalesQuery->with('product')->get();
        $todayFullyPaidSales = $todaySales->filter(function ($record) {
            return !$record->is_credit || $record->is_paid_in_full;
        });

        // Revenue calculations (cash sales + all payments made on credit sales)
        $cashSalesRevenue = $allSales->filter(function ($r) { return !$r->is_credit; })->sum('amount');
        $creditSalesRevenue = $allSales->filter(function ($r) { return $r->is_credit; })->sum('paid_amount');
        $totalRevenue = $cashSalesRevenue + $creditSalesRevenue;

        $periodCashSalesRevenue = $salesRecords->filter(function ($r) { return !$r->is_credit; })->sum('amount');
        $periodCreditSalesRevenue = $salesRecords->filter(function ($r) { return $r->is_credit; })->sum('paid_amount');
        $periodRevenue = $periodCashSalesRevenue + $periodCreditSalesRevenue;

        $todayCashSalesRevenue = $todaySales->filter(function ($r) { return !$r->is_credit; })->sum('amount');
        $todayCreditSalesRevenue = $todaySales->filter(function ($r) { return $r->is_credit; })->sum('paid_amount');
        $todayRevenue = $todayCashSalesRevenue + $todayCreditSalesRevenue;

        // Profit and COGS calculations: ONLY fully paid sales (cash + fully paid credit sales)
        $totalCogs = $fullyPaidSales->sum('cost_of_goods_sold');
        $periodCogs = $periodFullyPaidSales->sum('cost_of_goods_sold');
        $todayCogs = $todayFullyPaidSales->sum('cost_of_goods_sold');

        // If COGS is not set, calculate from product buying price
        if ($totalCogs == 0) {
            $totalCogs = $fullyPaidSales
                ->whereNotNull('product_id')
                ->sum(function ($record) {
                    return ($record->product?->buying_price ?? 0) * ($record->quantity ?? 1);
                });
        }
        if ($periodCogs == 0) {
            $periodCogs = $periodFullyPaidSales
                ->whereNotNull('product_id')
                ->sum(function ($record) {
                    return ($record->product?->buying_price ?? 0) * ($record->quantity ?? 1);
                });
        }
        if ($todayCogs == 0) {
            $todayCogs = $todayFullyPaidSales
                ->whereNotNull('product_id')
                ->sum(function ($record) {
                    return ($record->product?->buying_price ?? 0) * ($record->quantity ?? 1);
                });
        }

        // Gross Profit calculations (partial profit for credit sales with paid_amount > COGS)
        $totalGrossProfit = 0;
        foreach ($allSales as $record) {
            if (!$record->is_credit) {
                // Cash sale: full profit
                $totalGrossProfit += $record->gross_profit;
            } else {
                $paid = $record->paid_amount;
                $cogs = $record->cost_of_goods_sold ?? 0;
                if ($cogs == 0 && $record->product && $record->quantity) {
                    $cogs = $record->product->buying_price * $record->quantity;
                }
                $maxProfit = ($record->total_amount ?? $record->amount) - $cogs;
                if ($paid > $cogs) {
                    $profit = min($paid - $cogs, $maxProfit);
                    $totalGrossProfit += $profit;
                }
            }
        }

        $periodGrossProfit = 0;
        foreach ($salesRecords as $record) {
            if (!$record->is_credit) {
                $periodGrossProfit += $record->gross_profit;
            } else {
                $paid = $record->paid_amount;
                $cogs = $record->cost_of_goods_sold ?? 0;
                if ($cogs == 0 && $record->product && $record->quantity) {
                    $cogs = $record->product->buying_price * $record->quantity;
                }
                $maxProfit = ($record->total_amount ?? $record->amount) - $cogs;
                if ($paid > $cogs) {
                    $profit = min($paid - $cogs, $maxProfit);
                    $periodGrossProfit += $profit;
                }
            }
        }

        $todayGrossProfit = 0;
        foreach ($todaySales as $record) {
            if (!$record->is_credit) {
                $todayGrossProfit += $record->gross_profit;
            } else {
                $paid = $record->paid_amount;
                $cogs = $record->cost_of_goods_sold ?? 0;
                if ($cogs == 0 && $record->product && $record->quantity) {
                    $cogs = $record->product->buying_price * $record->quantity;
                }
                $maxProfit = ($record->total_amount ?? $record->amount) - $cogs;
                if ($paid > $cogs) {
                    $profit = min($paid - $cogs, $maxProfit);
                    $todayGrossProfit += $profit;
                }
            }
        }

        // Expense calculations
        $totalExpensesQuery = BusinessRecord::where('business_id', $user->business_id)->expenses();
        $todayExpensesQuery = BusinessRecord::where('business_id', $user->business_id)->expenses()->today();
        
        // If salesperson, filter to only their records
        if ($user->role === 'salesperson') {
            $totalExpensesQuery->where('user_id', $user->id);
            $todayExpensesQuery->where('user_id', $user->id);
        }
        
        $totalExpenses = $totalExpensesQuery->sum('amount');
        $periodExpenses = $expenseRecords->sum('amount');
        $todayExpenses = $todayExpensesQuery->sum('amount');

        // Purchase calculations (only revenue-funded purchases affect profit)
        $totalPurchasesQuery = BusinessRecord::where('business_id', $user->business_id)->purchases()->revenueFunded();
        $todayPurchasesQuery = BusinessRecord::where('business_id', $user->business_id)->purchases()->revenueFunded()->today();
        
        // If salesperson, filter to only their records
        if ($user->role === 'salesperson') {
            $totalPurchasesQuery->where('user_id', $user->id);
            $todayPurchasesQuery->where('user_id', $user->id);
        }
        
        $totalPurchases = $totalPurchasesQuery->sum('amount');
        $periodPurchases = $purchaseRecords->where('funding_source', 'revenue')->sum('amount');
        $todayPurchases = $todayPurchasesQuery->sum('amount');

        // Net Profit calculations (Gross Profit - Expenses - Revenue-funded Purchases)
        $totalNetProfit = $totalGrossProfit - $totalExpenses - $totalPurchases;
        $periodNetProfit = $periodGrossProfit - $periodExpenses - $periodPurchases;
        $todayNetProfit = $todayGrossProfit - $todayExpenses - $todayPurchases;

        $metrics = [
            // Revenue metrics
            'total_revenue' => $totalRevenue,
            'period_revenue' => $periodRevenue,
            'today_revenue' => $todayRevenue,
            
            // Cost of Goods Sold metrics
            'total_cost_of_goods_sold' => $totalCogs,
            'period_cost_of_goods_sold' => $periodCogs,
            'today_cost_of_goods_sold' => $todayCogs,
            
            // Gross Profit metrics (Faida ya Mauzo)
            'total_gross_profit' => $totalGrossProfit,
            'period_gross_profit' => $periodGrossProfit,
            'today_gross_profit' => $todayGrossProfit,
            
            // Expense metrics
            'total_expenses' => $totalExpenses,
            'period_expenses' => $periodExpenses,
            'today_expenses' => $todayExpenses,
            
            // Purchase metrics (only revenue-funded)
            'total_purchases_revenue_funded' => $totalPurchases,
            'period_purchases_revenue_funded' => $periodPurchases,
            'today_purchases_revenue_funded' => $todayPurchases,
            
            // Net Profit metrics (Faida baada ya Matumizi)
            'total_net_profit' => $totalNetProfit,
            'period_net_profit' => $periodNetProfit,
            'today_net_profit' => $todayNetProfit,
            
            // Legacy fields for backward compatibility
            'total_profit' => $totalNetProfit,
            'period_profit' => $periodNetProfit,
            'today_profit' => $todayNetProfit,
            
            // Inventory metrics
            'total_products' => $user->inventoryItems()->active()->count(),
            'low_stock_items' => $user->inventoryItems()->active()->lowStock()->count(),
            'out_of_stock_items' => $user->inventoryItems()->active()->outOfStock()->count(),
            'total_stock_value' => $user->inventoryItems()->active()
                ->sum(DB::raw('current_stock * buying_price')),
            
            // Credit metrics
            'total_credit_sales' => BusinessRecord::where('business_id', $user->business_id)->creditSales()->sum('total_amount'),
            'total_debt' => BusinessRecord::where('business_id', $user->business_id)->creditSales()->sum('debt_amount'),
            'customers_with_debt' => BusinessRecord::where('business_id', $user->business_id)->creditSales()
                ->where('debt_amount', '>', 0)->distinct('customer_name')->count(),
            
            // Funding source metrics
            'total_purchases_personal_funded' => BusinessRecord::where('business_id', $user->business_id)->purchases()->personalFunded()->sum('amount'),
            'period_purchases_personal_funded' => $purchaseRecords->where('funding_source', 'personal')->sum('amount'),
        ];

        return response()->json([
            'success' => true,
            'data' => $metrics,
            'period' => $period,
            'date_range' => [
                'start' => $startDate->toDateString(),
                'end' => $endDate->toDateString()
            ]
        ]);
    }

    public function businessHealth(Request $request)
    {
        $user = auth()->user();
        $health = $this->calculateBusinessHealth($user);

        return response()->json([
            'success' => true,
            'data' => $health
        ]);
    }

    public function salesTrends(Request $request)
    {
        $user = auth()->user();
        $period = $request->get('period', 'week'); // week, month, year
        $days = $this->getPeriodDays($period);

        $trends = [];
        for ($i = $days - 1; $i >= 0; $i--) {
            $date = now()->subDays($i);
            $sales = BusinessRecord::where('business_id', $user->business_id)->sales()
                ->whereDate('date', $date)
                ->sum('amount');
            
            $trends[] = [
                'date' => $date->toDateString(),
                'sales' => $sales,
                'day_name' => $date->format('D'),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $trends,
            'period' => $period
        ]);
    }

    public function topProducts(Request $request)
    {
        $user = auth()->user();
        $limit = $request->get('limit', 10);
        $period = $request->get('period', 'month');
        $startDate = $this->getStartDate($period);

        $topProducts = BusinessRecord::where('business_id', $user->business_id)
            ->sales()
            ->whereNotNull('product_id')
            ->byDateRange($startDate, now())
            ->select('product_id', DB::raw('SUM(quantity) as total_quantity'), DB::raw('SUM(amount) as total_sales'))
            ->with('product:id,name,category,selling_price')
            ->groupBy('product_id')
            ->orderBy('total_sales', 'desc')
            ->limit($limit)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $topProducts,
            'period' => $period
        ]);
    }

    public function expenseBreakdown(Request $request)
    {
        $user = auth()->user();
        $period = $request->get('period', 'month');
        $startDate = $this->getStartDate($period);

        $expenses = BusinessRecord::where('business_id', $user->business_id)
            ->expenses()
            ->byDateRange($startDate, now())
            ->select('category', DB::raw('SUM(amount) as total_amount'), DB::raw('COUNT(*) as count'))
            ->groupBy('category')
            ->orderBy('total_amount', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $expenses,
            'period' => $period
        ]);
    }

    public function recentActivities(Request $request)
    {
        $user = auth()->user();
        $limit = $request->get('limit', 20);

        $activities = BusinessRecord::where('business_id', $user->business_id)
            ->with('product:id,name')
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get()
            ->map(function ($record) {
                return [
                    'id' => $record->id,
                    'type' => $record->type,
                    'description' => $record->description,
                    'amount' => $record->amount,
                    'date' => $record->date,
                    'created_at' => $record->created_at,
                    'customer_name' => $record->customer_name,
                    'supplier_name' => $record->supplier_name,
                    'product_name' => $record->product?->name,
                    'is_credit' => $record->is_credit,
                    'payment_status' => $record->payment_status_label,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $activities
        ]);
    }

    private function getBusinessMetrics($user)
    {
        $today = now()->startOfDay();
        $thisMonth = now()->startOfMonth();

        return [
            'daily_revenue' => $user->businessRecords()->sales()->whereDate('date', $today)->sum('amount'),
            'daily_expenses' => $user->businessRecords()->expenses()->whereDate('date', $today)->sum('amount'),
            'daily_profit' => $user->businessRecords()->sales()->whereDate('date', $today)->sum('amount') - 
                            $user->businessRecords()->expenses()->whereDate('date', $today)->sum('amount'),
            
            'monthly_revenue' => $user->businessRecords()->sales()->where('date', '>=', $thisMonth)->sum('amount'),
            'monthly_expenses' => $user->businessRecords()->expenses()->where('date', '>=', $thisMonth)->sum('amount'),
            'monthly_profit' => $user->businessRecords()->sales()->where('date', '>=', $thisMonth)->sum('amount') - 
                              $user->businessRecords()->expenses()->where('date', '>=', $thisMonth)->sum('amount'),
            
            'total_revenue' => $user->businessRecords()->sales()->sum('amount'),
            'total_expenses' => $user->businessRecords()->expenses()->sum('amount'),
            'total_profit' => $user->businessRecords()->sales()->sum('amount') - 
                            $user->businessRecords()->expenses()->sum('amount'),
        ];
    }

    private function getBusinessHealth($user)
    {
        return $this->calculateBusinessHealth($user);
    }

    private function calculateBusinessHealth($user)
    {
        $score = 0;
        $factors = [];

        // Factor 1: Profit Margin (30 points)
        $totalRevenue = $user->businessRecords()->sales()->sum('amount');
        $totalExpenses = $user->businessRecords()->expenses()->sum('amount');
        
        if ($totalRevenue > 0) {
            $profitMargin = (($totalRevenue - $totalExpenses) / $totalRevenue) * 100;
            if ($profitMargin >= 30) {
                $profitScore = 30;
            } elseif ($profitMargin >= 20) {
                $profitScore = 25;
            } elseif ($profitMargin >= 10) {
                $profitScore = 20;
            } elseif ($profitMargin >= 0) {
                $profitScore = 10;
            } else {
                $profitScore = 0;
            }
            $score += $profitScore;
            $factors['profit_margin'] = [
                'score' => $profitScore,
                'value' => round($profitMargin, 2),
                'status' => $profitMargin >= 20 ? 'good' : ($profitMargin >= 10 ? 'average' : 'poor')
            ];
        }

        // Factor 2: Stock Management (25 points)
        $totalProducts = $user->inventoryItems()->active()->count();
        $lowStockItems = $user->inventoryItems()->active()->lowStock()->count();
        
        if ($totalProducts > 0) {
            $stockRatio = ($totalProducts - $lowStockItems) / $totalProducts;
            $stockScore = round($stockRatio * 25);
            $score += $stockScore;
            $factors['stock_management'] = [
                'score' => $stockScore,
                'low_stock_items' => $lowStockItems,
                'total_items' => $totalProducts,
                'status' => $stockRatio >= 0.9 ? 'good' : ($stockRatio >= 0.7 ? 'average' : 'poor')
            ];
        }

        // Factor 3: Revenue Growth (25 points)
        $thisMonth = $user->businessRecords()->sales()->thisMonth()->sum('amount');
        $lastMonth = $user->businessRecords()->sales()
            ->whereMonth('date', now()->subMonth()->month)
            ->whereYear('date', now()->subMonth()->year)
            ->sum('amount');
        
        if ($lastMonth > 0) {
            $growthRate = (($thisMonth - $lastMonth) / $lastMonth) * 100;
            if ($growthRate >= 20) {
                $growthScore = 25;
            } elseif ($growthRate >= 10) {
                $growthScore = 20;
            } elseif ($growthRate >= 0) {
                $growthScore = 15;
            } else {
                $growthScore = 5;
            }
            $score += $growthScore;
            $factors['revenue_growth'] = [
                'score' => $growthScore,
                'growth_rate' => round($growthRate, 2),
                'status' => $growthRate >= 10 ? 'good' : ($growthRate >= 0 ? 'average' : 'poor')
            ];
        }

        // Factor 4: Debt Management (20 points)
        $totalDebt = $user->businessRecords()->creditSales()->sum('debt_amount');
        $totalCreditSales = $user->businessRecords()->creditSales()->sum('total_amount');
        
        if ($totalCreditSales > 0) {
            $debtRatio = $totalDebt / $totalCreditSales;
            if ($debtRatio <= 0.1) {
                $debtScore = 20;
            } elseif ($debtRatio <= 0.3) {
                $debtScore = 15;
            } elseif ($debtRatio <= 0.5) {
                $debtScore = 10;
            } else {
                $debtScore = 5;
            }
            $score += $debtScore;
            $factors['debt_management'] = [
                'score' => $debtScore,
                'debt_ratio' => round($debtRatio * 100, 2),
                'total_debt' => $totalDebt,
                'status' => $debtRatio <= 0.2 ? 'good' : ($debtRatio <= 0.4 ? 'average' : 'poor')
            ];
        }

        // Determine overall status
        $status = 'poor';
        $statusText = 'Biashara Inahitaji Uboreshaji';
        
        if ($score >= 80) {
            $status = 'excellent';
            $statusText = 'Biashara Ina Afya Nzuri Sana';
        } elseif ($score >= 60) {
            $status = 'good';
            $statusText = 'Biashara Ina Afya Nzuri';
        } elseif ($score >= 40) {
            $status = 'average';
            $statusText = 'Biashara Ina Afya ya Wastani';
        }

        return [
            'score' => $score,
            'status' => $status,
            'status_text' => $statusText,
            'factors' => $factors,
            'recommendations' => $this->getHealthRecommendations($factors)
        ];
    }

    private function getHealthRecommendations($factors)
    {
        $recommendations = [];

        if (isset($factors['profit_margin']) && $factors['profit_margin']['status'] !== 'good') {
            $recommendations[] = 'Ongeza bei za mauzo au punguza gharama za biashara';
        }

        if (isset($factors['stock_management']) && $factors['stock_management']['status'] !== 'good') {
            $recommendations[] = 'Ongeza hifadhi ya bidhaa zinazokwisha haraka';
        }

        if (isset($factors['revenue_growth']) && $factors['revenue_growth']['status'] !== 'good') {
            $recommendations[] = 'Tafuta njia za kuongeza mauzo kwa mfano uuzaji mkubwa';
        }

        if (isset($factors['debt_management']) && $factors['debt_management']['status'] !== 'good') {
            $recommendations[] = 'Fuatilia madeni ya wateja na uwahimize kulipa mapema';
        }

        if (empty($recommendations)) {
            $recommendations[] = 'Endelea kufanya vizuri! Fuatilia takwimu za biashara yako kila siku';
        }

        return $recommendations;
    }

    private function getRecentActivities($user)
    {
        $query = BusinessRecord::where('business_id', $user->business_id);
        
        // If salesperson, only show their own activities
        if ($user->role === 'salesperson') {
            $query->where('user_id', $user->id);
        }
        
        return $query->with('product:id,name')
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get()
            ->map(function ($record) {
                return [
                    'id' => $record->id,
                    'type' => $record->type,
                    'description' => $record->description,
                    'amount' => $record->amount,
                    'date' => $record->date,
                    'created_at' => $record->created_at,
                    'customer_name' => $record->customer_name,
                    'supplier_name' => $record->supplier_name,
                    'product_name' => $record->product?->name,
                    'is_credit' => $record->is_credit,
                    'payment_status' => $record->payment_status_label,
                ];
            });
    }

    private function getLowStockAlerts($user)
    {
        return $user->inventoryItems()
            ->active()
            ->lowStock()
            ->select('id', 'name', 'current_stock', 'minimum_stock', 'category')
            ->orderBy('current_stock', 'asc')
            ->limit(5)
            ->get();
    }

    private function getQuickStats($user)
    {
        $today = now()->startOfDay();
        $businessId = $user->business_id;
        
        // Base queries for business
        $salesQuery = BusinessRecord::where('business_id', $businessId)->sales();
        $purchasesQuery = BusinessRecord::where('business_id', $businessId)->purchases();
        $expensesQuery = BusinessRecord::where('business_id', $businessId)->expenses();
        $creditSalesQuery = BusinessRecord::where('business_id', $businessId)->creditSales();
        $customersQuery = BusinessRecord::where('business_id', $businessId)->sales();
        $inventoryQuery = InventoryItem::where('business_id', $businessId);
        
        // If salesperson, filter to only their records
        if ($user->role === 'salesperson') {
            $salesQuery->where('user_id', $user->id);
            $purchasesQuery->where('user_id', $user->id);
            $expensesQuery->where('user_id', $user->id);
            $creditSalesQuery->where('user_id', $user->id);
            $customersQuery->where('user_id', $user->id);
        }
        
        return [
            'today_sales_count' => $salesQuery->whereDate('date', $today)->count(),
            'today_purchases_count' => $purchasesQuery->whereDate('date', $today)->count(),
            'today_expenses_count' => $expensesQuery->whereDate('date', $today)->count(),
            'pending_debts_count' => $creditSalesQuery->where('debt_amount', '>', 0)->count(),
            'low_stock_count' => $inventoryQuery->active()->lowStock()->count(),
            'total_customers' => $customersQuery->whereNotNull('customer_name')->distinct('customer_name')->count(),
        ];
    }

    private function getActivityIcon($type)
    {
        return match($type) {
            'sale' => 'point_of_sale',
            'purchase' => 'shopping_cart',
            'expense' => 'money_off',
            default => 'receipt'
        };
    }

    private function getActivityColor($type)
    {
        return match($type) {
            'sale' => 'green',
            'purchase' => 'blue',
            'expense' => 'red',
            default => 'grey'
        };
    }

    private function getStartDate($period)
    {
        return match($period) {
            'day' => now()->startOfDay(),
            'week' => now()->startOfWeek(),
            'month' => now()->startOfMonth(),
            'year' => now()->startOfYear(),
            default => now()->startOfMonth()
        };
    }

    private function getPeriodDays($period)
    {
        return match($period) {
            'week' => 7,
            'month' => 30,
            'year' => 365,
            default => 7
        };
    }
}

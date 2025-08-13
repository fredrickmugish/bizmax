<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BusinessRecord;
use App\Models\InventoryItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Tymon\JWTAuth\Facades\JWTAuth;

class BusinessRecordController extends Controller
{

    public function index(Request $request)
    {
        $user = auth()->user();
        $role = $user->role;
        $query = BusinessRecord::with(['product', 'user'])
            ->where('business_id', $user->business_id);

        // If salesperson, only show their own records
        if ($role === 'salesperson') {
            $query->where('user_id', $user->id);
        }

        // Type filter
        if ($request->has('type') && $request->type) {
            $query->byType($request->type);
        }

        // Date range filter
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->byDateRange($request->start_date, $request->end_date);
        }

        // Search
        if ($request->has('search') && $request->search) {
            $query->search($request->search);
        }

        // Credit sales filter
        if ($request->has('credit_only') && $request->credit_only) {
            $query->creditSales();
        }

        // Debt filter
        if ($request->has('with_debt') && $request->with_debt) {
            $query->withDebt();
        }

        // Sorting
        $sortBy = $request->get('sort_by', 'date');
        $sortOrder = $request->get('sort_order', 'desc');
        
        if ($sortBy === 'date') {
            $query->orderBy('date', $sortOrder)->orderBy('created_at', $sortOrder);
        } else {
            $query->orderBy($sortBy, $sortOrder);
        }

        $perPage = $request->get('per_page', 15);
        $records = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $records,
            'summary' => $this->getRecordsSummary($request)
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:sale,purchase,expense',
            'description' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0',
            'date' => 'required|date',
            'category' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
            'customer_name' => 'nullable|string|max:255',
            'supplier_name' => 'nullable|string|max:255',
            'product_id' => 'nullable|exists:inventory_items,id',
            'quantity' => 'nullable|integer|min:1',
            'unit_price' => 'nullable|numeric|min:0',
            'cost_of_goods_sold' => 'nullable|numeric|min:0',
            'funding_source' => 'nullable|in:revenue,personal',
            'is_credit_sale' => 'boolean',
            'sale_type' => 'nullable|string|in:wholesale,retail,discount',
            'total_amount' => 'nullable|numeric|min:0',
            'amount_paid' => 'nullable|numeric|min:0',
            'due_date' => 'nullable|date|after:date',
            'transaction_id' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Additional validation for credit sales
        if ($request->type === 'sale' && $request->is_credit_sale) {
            if (!$request->customer_name) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer name is required for credit sales'
                ], 422);
            }

            if (!$request->total_amount) {
                return response()->json([
                    'success' => false,
                    'message' => 'Total amount is required for credit sales'
                ], 422);
            }
        }

        DB::beginTransaction();
        try {
            // Create the business record
            $recordData = $request->all();
            $recordData['user_id'] = auth()->id();
            $recordData['business_id'] = auth()->user()->business_id; // Set business_id automatically

            // Set default funding source based on record type
            if ($request->type === 'purchase') {
                $recordData['funding_source'] = $request->funding_source ?? 'revenue';
            } else {
                // For sales and expenses, funding_source is not applicable
                $recordData['funding_source'] = null;
            }

            // Handle credit sale calculations
            if ($request->type === 'sale' && $request->is_credit_sale) {
                $totalAmount = $request->total_amount;
                $amountPaid = $request->amount_paid ?? 0;
                $debtAmount = $totalAmount - $amountPaid;

                $recordData['total_amount'] = $totalAmount;
                $recordData['amount_paid'] = $amountPaid;
                $recordData['debt_amount'] = $debtAmount;
                $recordData['amount'] = $amountPaid; // Income is what was actually paid
                $recordData['payment_status'] = $debtAmount > 0 ? ($amountPaid > 0 ? 'partial' : 'pending') : 'paid';
            }

            $record = BusinessRecord::create($recordData);

            // Handle inventory updates
            if ($request->product_id && $request->quantity) {
                $product = InventoryItem::findOrFail($request->product_id);

                if ($request->type === 'sale') {
                    // Check stock availability
                    if ($product->current_stock < $request->quantity) {
                        throw new \Exception('Insufficient stock. Available: ' . $product->current_stock);
                    }
                    // Reduce stock
                    $product->adjustStock(-$request->quantity, 'sale', "Sale: {$record->description}");
                } elseif ($request->type === 'purchase') {
                    // Increase stock
                    $product->adjustStock($request->quantity, 'purchase', "Purchase: {$record->description}");
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Record created successfully',
                'data' => $record->load('product')
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 400);
        }
    }

    public function show($id)
    {
        $user = auth()->user();
        $record = BusinessRecord::with(['product', 'payments', 'user'])
            ->where('business_id', $user->business_id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data' => $record
        ]);
    }

    public function update(Request $request, $id)
    {
        $user = auth()->user();
        $record = BusinessRecord::where('business_id', $user->business_id)
            ->where('id', $id)
            ->firstOrFail();

        $validator = Validator::make($request->all(), [
            'description' => 'sometimes|string|max:255',
            'amount' => 'sometimes|numeric|min:0',
            'date' => 'sometimes|date',
            'category' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
            'customer_name' => 'nullable|string|max:255',
            'supplier_name' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $record->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Record updated successfully',
            'data' => $record
        ]);
    }

    public function destroy($id)
    {
        $user = auth()->user();
        $record = BusinessRecord::where('business_id', $user->business_id)
            ->where('id', $id)
            ->firstOrFail();

        DB::beginTransaction();
        try {
            // Reverse inventory changes if applicable
            if ($record->product_id && $record->quantity) {
                $product = InventoryItem::find($record->product_id);
                if ($product) {
                    if ($record->type === 'sale') {
                        // Add stock back
                        $product->adjustStock($record->quantity, 'adjustment', "Reversed sale: {$record->description}");
                    } elseif ($record->type === 'purchase') {
                        // Remove stock
                        $product->adjustStock(-$record->quantity, 'adjustment', "Reversed purchase: {$record->description}");
                    }
                }
            }

            $record->delete();
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Record deleted successfully'
            ]);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 400);
        }
    }

    public function makePayment(Request $request, $id)
    {
        $user = auth()->user();
        $record = BusinessRecord::where('business_id', $user->business_id)
            ->where('id', $id)
            ->firstOrFail();

        if ($record->type !== 'sale' || !$record->is_credit_sale) {
            return response()->json([
                'success' => false,
                'message' => 'Payment can only be made for credit sales'
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:0.01|max:' . $record->debt_amount,
            'notes' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $record->makePayment($request->amount, $request->notes);

            return response()->json([
                'success' => true,
                'message' => 'Payment recorded successfully',
                'data' => $record->fresh(['payments'])
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 400);
        }
    }

    public function creditSales(Request $request)
    {
        $user = auth()->user();
        $query = BusinessRecord::where('business_id', $user->business_id)
            ->creditSales()
            ->with('product');

        // Filter by payment status
        if ($request->has('payment_status')) {
            switch ($request->payment_status) {
                case 'unpaid':
                    $query->where('amount_paid', 0);
                    break;
                case 'partial':
                    $query->where('amount_paid', '>', 0)->where('debt_amount', '>', 0);
                    break;
                case 'paid':
                    $query->where('debt_amount', '<=', 0);
                    break;
            }
        }

        $records = $query->orderBy('date', 'desc')->paginate(15);

        $summary = [
            'total_credit_sales' => BusinessRecord::where('business_id', $user->business_id)->creditSales()->sum('total_amount'),
            'total_paid' => BusinessRecord::where('business_id', $user->business_id)->creditSales()->sum('amount_paid'),
            'total_debt' => BusinessRecord::where('business_id', $user->business_id)->creditSales()->sum('debt_amount'),
        ];

        return response()->json([
            'success' => true,
            'data' => $records,
            'summary' => $summary
        ]);
    }

    public function getRecordsByTransactionId($transactionId)
    {
        $user = auth()->user();
        $records = BusinessRecord::where('business_id', $user->business_id)
            ->where('transaction_id', $transactionId)
            ->with('product')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $records
        ]);
    }

    private function getRecordsSummary($request)
    {
        $user = auth()->user();
        $query = BusinessRecord::where('business_id', $user->business_id);

        // If salesperson, only show their own records in summary
        if ($user->role === 'salesperson') {
            $query->where('user_id', $user->id);
        }

        // Apply same filters as main query
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->byDateRange($request->start_date, $request->end_date);
        }

        return [
            'total_sales' => (clone $query)->sales()->sum('amount'),
            'total_purchases' => (clone $query)->purchases()->sum('amount'),
            'total_expenses' => (clone $query)->expenses()->sum('amount'),
            'total_records' => $query->count(),
        ];
    }
}

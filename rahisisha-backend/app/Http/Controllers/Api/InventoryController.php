<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventoryItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class InventoryController extends Controller
{
    public function index(Request $request)
    {
        $user = auth()->user();
        $businessId = $user->business_id;

        // Get inventory items for the business
        $query = InventoryItem::where('business_id', $businessId)->active();

        // Search
        if ($request->has('search') && $request->search) {
            $query->search($request->search);
        }

        // Category filter
        if ($request->has('category') && $request->category && $request->category !== 'All') {
            $query->byCategory($request->category);
        }

        // Stock status filter
        if ($request->has('stock_status')) {
            switch ($request->stock_status) {
                case 'low_stock':
                    $query->lowStock();
                    break;
                case 'out_of_stock':
                    $query->outOfStock();
                    break;
            }
        }

        // Sorting
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $perPage = $request->get('per_page', 15);
        $items = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $items,
            'summary' => [
                'total_items' => InventoryItem::where('business_id', $businessId)->active()->count(),
                'low_stock_items' => InventoryItem::where('business_id', $businessId)->active()->lowStock()->count(),
                'out_of_stock_items' => InventoryItem::where('business_id', $businessId)->active()->outOfStock()->count(),
                'total_stock_value' => InventoryItem::where('business_id', $businessId)->active()->sum(\DB::raw('current_stock * buying_price')),
            ]
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            // --- CHANGE HERE: Make category nullable ---
            'category' => 'nullable|string|max:255',
            // --- END CHANGE ---
            'unit' => 'required|string|max:50',
            'buying_price' => 'required|numeric|min:0',
            'selling_price' => 'required|numeric|min:0|gt:buying_price',
            'current_stock' => 'required|integer|min:0',
            'minimum_stock' => 'required|integer|min:0',
            'description' => 'nullable|string',
            'barcode' => 'nullable|string|max:255',
            'sku' => 'nullable|string|max:255',
            'product_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $request->all();
        $data['business_id'] = auth()->user()->business_id;

        // Handle case where category might be an empty string and you want to store null
        // if (empty($data['category'])) {
        //     $data['category'] = null;
        // }

        if ($request->hasFile('product_image')) {
            $image = $request->file('product_image');
            $imagePath = $image->store('product_images', 'public');
            $data['product_image'] = '/storage/' . $imagePath;
        }

        $item = auth()->user()->inventoryItems()->create($data);

        // Create initial stock movement
        $item->stockMovements()->create([
            'user_id' => auth()->id(),
            'type' => 'manual',
            'quantity_before' => 0,
            'quantity_after' => $item->current_stock,
            'quantity_changed' => $item->current_stock,
            'reason' => 'Initial stock entry',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Product added successfully',
            'data' => $item->load('stockMovements')
        ], 201);
    }

    public function show($id)
    {
        $businessId = auth()->user()->business_id;
        $item = InventoryItem::where('business_id', $businessId)
            ->with(['stockMovements' => function($query) {
                $query->latest()->limit(10);
            }])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $item
        ]);
    }

    public function update(Request $request, $id)
    {
        $businessId = auth()->user()->business_id;
        $item = InventoryItem::where('business_id', $businessId)->findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            // --- CHANGE HERE: Make category nullable for update ---
            'category' => 'nullable|string|max:255', // Use nullable, not sometimes required
            // --- END CHANGE ---
            'unit' => 'sometimes|string|max:50',
            'buying_price' => 'sometimes|numeric|min:0',
            'selling_price' => 'sometimes|numeric|min:0',
            'current_stock' => 'sometimes|integer|min:0',
            'minimum_stock' => 'sometimes|integer|min:0',
            'description' => 'nullable|string',
            'barcode' => 'nullable|string|max:255',
            'sku' => 'nullable|string|max:255',
            'product_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $request->all();

        // Handle case where category might be an empty string and you want to store null
        // if (isset($data['category']) && empty($data['category'])) {
        //     $data['category'] = null;
        // }

        if ($request->hasFile('product_image')) {
            $image = $request->file('product_image');
            $imagePath = $image->store('product_images', 'public');
            $data['product_image'] = '/storage/' . $imagePath;
        }

        // Handle stock update separately
        if ($request->has('current_stock') && $request->current_stock != $item->current_stock) {
            $item->updateStock($request->current_stock, 'manual', 'Stock updated via API');
            $request->request->remove('current_stock'); // Remove from update array to prevent double handling
        }

        $item->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully',
            'data' => $item
        ]);
    }

    public function destroy($id)
    {
        $businessId = auth()->user()->business_id;
        $item = InventoryItem::where('business_id', $businessId)->findOrFail($id);
        $item->delete();

        return response()->json([
            'success' => true,
            'message' => 'Product deleted successfully'
        ]);
    }

    public function updateStock(Request $request, $id)
    {
        $businessId = auth()->user()->business_id;
        $item = InventoryItem::where('business_id', $businessId)->findOrFail($id);

        $validator = Validator::make($request->all(), [
            'quantity' => 'required|integer|min:0',
            'type' => 'sometimes|string|in:manual,adjustment,sale,purchase',
            'reason' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $type = $request->get('type', 'manual');
        $reason = $request->get('reason', 'Stock updated via API');

        $item->updateStock($request->quantity, $type, $reason);

        return response()->json([
            'success' => true,
            'message' => 'Stock updated successfully',
            'data' => $item->fresh()
        ]);
    }

    public function adjustStock(Request $request, $id)
    {
        $businessId = auth()->user()->business_id;
        $item = InventoryItem::where('business_id', $businessId)->findOrFail($id);

        $validator = Validator::make($request->all(), [
            'adjustment' => 'required|integer',
            'reason' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $reason = $request->get('reason', 'Stock adjustment via API');
        $item->adjustStock($request->adjustment, 'adjustment', $reason);

        return response()->json([
            'success' => true,
            'message' => 'Stock adjusted successfully',
            'data' => $item->fresh()
        ]);
    }

    public function categories()
    {
        $businessId = auth()->user()->business_id;
        $categories = InventoryItem::where('business_id', $businessId)
            ->select('category')
            ->distinct()
            ->pluck('category')
            ->filter(fn($category) => !is_null($category) && $category !== '') // Filter out nulls and empty strings
            ->toArray();

        // Add default categories from constants
        $defaultCategories = [
            'Chakula na Vinywaji',
            'Nguo na Vazi',
            'Elektroniki',
            'Nyumbani na Bustani',
            'Afya na Urembo',
            'Michezo na Burudani',
            'Vitabu na Elimu',
            'Gari na Usafiri',
            'Nyingine'
        ];

        $allCategories = array_unique(array_merge($defaultCategories, $categories));

        return response()->json([
            'success' => true,
            'data' => array_values($allCategories)
        ]);
    }

    public function lowStock()
    {
        $businessId = auth()->user()->business_id;
        $items = InventoryItem::where('business_id', $businessId)
            ->active()
            ->lowStock()
            ->orderBy('current_stock', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $items,
            'count' => $items->count()
        ]);
    }

    public function stockMovements($id)
    {
        $businessId = auth()->user()->business_id;
        $item = InventoryItem::where('business_id', $businessId)->findOrFail($id);
        $movements = $item->stockMovements()
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $movements
        ]);
    }
}
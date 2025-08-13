<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class InventoryItem extends Model
{
    use HasFactory, SoftDeletes, LogsActivity;

    protected $fillable = [
        'user_id',
        'business_id',
        'name',
        'category',
        'unit',
        'buying_price',
        'wholesale_price',
        'retail_price',
        'selling_price',
        'unit_dimensions',
        'unit_quantity',
        'current_stock',
        'minimum_stock',
        'description',
        'barcode',
        'sku',
        'product_image',
        'is_active',
    ];

    protected $casts = [
        'buying_price' => 'decimal:2',
        'wholesale_price' => 'decimal:2',
        'retail_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'unit_quantity' => 'decimal:3',
        'current_stock' => 'integer',
        'minimum_stock' => 'integer',
        'is_active' => 'boolean',
    ];

    protected $appends = [
        'quantity',
        'min_stock_level',
        'stock_value',
        'wholesale_stock_value',
        'retail_stock_value',
        'is_low_stock',
        'is_out_of_stock',
        'profit_margin_wholesale',
        'profit_margin_retail',
    ];

    // Activity Log
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'category', 'buying_price', 'wholesale_price', 'retail_price', 'current_stock', 'unit_dimensions'])
            ->logOnlyDirty();
    }

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function business()
    {
        return $this->belongsTo(Business::class);
    }

    public function businessRecords()
    {
        return $this->hasMany(BusinessRecord::class, 'product_id');
    }

    public function stockMovements()
    {
        return $this->hasMany(StockMovement::class, 'inventory_item_id');
    }

    // Accessors
    public function getQuantityAttribute()
    {
        return $this->current_stock;
    }

    public function getMinStockLevelAttribute()
    {
        return $this->minimum_stock;
    }

    public function getStockValueAttribute()
    {
        return $this->current_stock * $this->buying_price;
    }

    public function getWholesaleStockValueAttribute()
    {
        return $this->current_stock * ($this->wholesale_price ?? $this->selling_price);
    }

    public function getRetailStockValueAttribute()
    {
        return $this->current_stock * ($this->retail_price ?? $this->selling_price);
    }

    public function getIsLowStockAttribute()
    {
        return $this->current_stock <= $this->minimum_stock && $this->current_stock > 0;
    }

    public function getIsOutOfStockAttribute()
    {
        return $this->current_stock <= 0;
    }

    public function getProfitMarginWholesaleAttribute()
    {
        $wholesalePrice = $this->wholesale_price ?? $this->selling_price;
        if ($wholesalePrice <= 0 || $this->buying_price <= 0) return 0;
        return (($wholesalePrice - $this->buying_price) / $wholesalePrice) * 100;
    }

    public function getProfitMarginRetailAttribute()
    {
        $retailPrice = $this->retail_price ?? $this->selling_price;
        if ($retailPrice <= 0 || $this->buying_price <= 0) return 0;
        return (($retailPrice - $this->buying_price) / $retailPrice) * 100;
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeByCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    public function scopeLowStock($query)
    {
        return $query->whereRaw('current_stock <= minimum_stock AND current_stock > 0');
    }

    public function scopeOutOfStock($query)
    {
        return $query->where('current_stock', '<=', 0);
    }

    public function scopeInStock($query)
    {
        return $query->where('current_stock', '>', 0);
    }

    public function scopeSearch($query, $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('name', 'like', "%{$search}%")
              ->orWhere('category', 'like', "%{$search}%")
              ->orWhere('description', 'like', "%{$search}%")
              ->orWhere('barcode', 'like', "%{$search}%")
              ->orWhere('sku', 'like', "%{$search}%");
        });
    }

    // Methods
    public function updateStock($quantity, $type = 'add', $notes = null)
    {
        $oldStock = $this->current_stock;
        
        if ($type === 'add') {
            $this->current_stock += $quantity;
        } elseif ($type === 'subtract') {
            $this->current_stock = max(0, $this->current_stock - $quantity);
        } elseif ($type === 'set') {
            $this->current_stock = max(0, $quantity);
        }

        $this->save();

        // Record stock movement
        $this->stockMovements()->create([
            'user_id' => $this->user_id,
            'inventory_item_id' => $this->id,
            'type' => $type,
            'quantity_before' => $oldStock,
            'quantity_after' => $this->current_stock,
            'quantity_changed' => $this->current_stock - $oldStock,
            'reason' => $notes,
        ]);

        return $this;
    }

    public function adjustStock($adjustment, $type = 'adjustment', $reason = null)
    {
        $oldStock = $this->current_stock;
        $this->current_stock = max(0, $this->current_stock + $adjustment);
        $this->save();

        // Record stock movement
        $this->stockMovements()->create([
            'user_id' => $this->user_id,
            'inventory_item_id' => $this->id,
            'type' => $type,
            'quantity_before' => $oldStock,
            'quantity_after' => $this->current_stock,
            'quantity_changed' => $adjustment,
            'reason' => $reason,
        ]);

        return $this;
    }

    public function getPriceByType($type = 'retail')
    {
        switch ($type) {
            case 'wholesale':
                return $this->wholesale_price ?? $this->selling_price;
            case 'retail':
                return $this->retail_price ?? $this->selling_price;
            default:
                return $this->selling_price;
        }
    }

    public function getFormattedUnit()
    {
        if ($this->unit_dimensions) {
            return $this->unit_dimensions;
        }
        return $this->unit;
    }

    public function getFullUnitDescription()
    {
        $unit = $this->getFormattedUnit();
        if ($this->unit_quantity > 1) {
            return "{$this->unit_quantity} {$unit}";
        }
        return $unit;
    }
}

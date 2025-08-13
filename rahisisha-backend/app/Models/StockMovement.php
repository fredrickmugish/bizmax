<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockMovement extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'inventory_item_id',
        'type', // sale, purchase, adjustment, manual
        'quantity_before',
        'quantity_after',
        'quantity_changed',
        'reason',
        'reference_id',
    ];

    protected $casts = [
        'quantity_before' => 'integer',
        'quantity_after' => 'integer',
        'quantity_changed' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function inventoryItem()
    {
        return $this->belongsTo(InventoryItem::class);
    }
}

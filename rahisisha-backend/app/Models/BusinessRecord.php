<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class BusinessRecord extends Model
{
    use HasFactory, SoftDeletes, LogsActivity;

    protected $fillable = [
        'user_id',
        'business_id',
        'transaction_id',
        'type', // sale, purchase, expense
        'description',
        'amount',
        'date',
        'category',
        'notes',
        'customer_name',
        'supplier_name',
        'product_id',
        'quantity',
        'unit_price',
        'cost_of_goods_sold',
        'funding_source',
        'is_credit_sale',
        'sale_type',
        'total_amount',
        'amount_paid',
        'debt_amount',
        'payment_status',
        'due_date',
        'reference_number',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'unit_price' => 'decimal:2',
        'cost_of_goods_sold' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'amount_paid' => 'decimal:2',
        'debt_amount' => 'decimal:2',
        'quantity' => 'integer',
        'date' => 'date',
        'due_date' => 'date',
        'is_credit_sale' => 'boolean',
    ];

    protected $appends = [
        'is_credit',
        'has_debt',
        'is_paid_in_full',
        'remaining_debt',
        'paid_amount',
        'sale_total',
        'payment_status_label',
        'gross_profit',
        'net_profit',
    ];

    // Activity Log
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['type', 'amount', 'cost_of_goods_sold', 'funding_source', 'payment_status', 'debt_amount'])
            ->logOnlyDirty();
    }

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function product()
    {
        return $this->belongsTo(InventoryItem::class, 'product_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    // Accessors (matching Flutter app logic)
    public function getIsCreditAttribute()
    {
        return $this->is_credit_sale === true;
    }

    public function getHasDebtAttribute()
    {
        return ($this->debt_amount ?? 0) > 0;
    }

    public function getIsPaidInFullAttribute()
    {
        return !$this->has_debt;
    }

    public function getRemainingDebtAttribute()
    {
        return $this->debt_amount ?? 0;
    }

    public function getPaidAmountAttribute()
    {
        return $this->amount_paid ?? $this->amount;
    }

    public function getSaleTotalAttribute()
    {
        return $this->total_amount ?? $this->amount;
    }

    public function getPaymentStatusLabelAttribute()
    {
        if ($this->type !== 'sale') return 'N/A';
        if (!$this->is_credit) return 'Fedha Taslimu';
        if ($this->is_paid_in_full) return 'Amelipa Kamili';
        if ($this->paid_amount > 0) return 'Amelipa Sehemu';
        return 'Hajalipa';
    }

    // New computed fields for profit calculation
    public function getGrossProfitAttribute()
    {
        if ($this->type !== 'sale') return 0;
        
        $revenue = $this->sale_total;
        $cogs = $this->cost_of_goods_sold ?? 0;
        
        // If no COGS is set, try to calculate from product
        if ($cogs == 0 && $this->product && $this->quantity) {
            $cogs = $this->product->buying_price * $this->quantity;
        }
        
        return $revenue - $cogs;
    }

    public function getNetProfitAttribute()
    {
        // Net profit calculation would require expense tracking per sale
        // For now, return gross profit. This can be enhanced later
        return $this->gross_profit;
    }

    // Scopes
    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeSales($query)
    {
        return $query->where('type', 'sale');
    }

    public function scopePurchases($query)
    {
        return $query->where('type', 'purchase');
    }

    public function scopeExpenses($query)
    {
        return $query->where('type', 'expense');
    }

    public function scopeCreditSales($query)
    {
        return $query->where('type', 'sale')->where('is_credit_sale', true);
    }

    public function scopeWithDebt($query)
    {
        return $query->where('debt_amount', '>', 0);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('date', [$startDate, $endDate]);
    }

    public function scopeToday($query)
    {
        return $query->whereDate('date', today());
    }

    public function scopeThisMonth($query)
    {
        return $query->whereMonth('date', now()->month)
                    ->whereYear('date', now()->year);
    }

    public function scopeByFundingSource($query, $source)
    {
        return $query->where('funding_source', $source);
    }

    public function scopeRevenueFunded($query)
    {
        return $query->where('funding_source', 'revenue');
    }

    public function scopePersonalFunded($query)
    {
        return $query->where('funding_source', 'personal');
    }

    public function scopeSearch($query, $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('description', 'like', "%{$search}%")
              ->orWhere('customer_name', 'like', "%{$search}%")
              ->orWhere('supplier_name', 'like', "%{$search}%")
              ->orWhere('reference_number', 'like', "%{$search}%")
              ->orWhere('notes', 'like', "%{$search}%");
        });
    }

    // Methods
    public function makePayment($amount, $notes = null)
    {
        if ($this->type !== 'sale' || !$this->is_credit_sale) {
            throw new \Exception('Payment can only be made for credit sales');
        }

        $newPaidAmount = $this->amount_paid + $amount;
        $newDebtAmount = max(0, $this->total_amount - $newPaidAmount);

        $this->update([
            'amount_paid' => $newPaidAmount,
            'debt_amount' => $newDebtAmount,
            'amount' => $newPaidAmount, // Update income amount
            'payment_status' => $newDebtAmount > 0 ? 'partial' : 'paid',
        ]);

        // Record payment
        $this->payments()->create([
            'user_id' => $this->user_id,
            'amount' => $amount,
            'payment_date' => now(),
            'notes' => $notes,
        ]);

        return $this;
    }
}

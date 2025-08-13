<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Backup extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'filename',
        'file_path',
        'file_size',
        'backup_type', // manual, automatic
        'status', // pending, completed, failed
        'data_types', // inventory, records, settings
    ];

    protected $casts = [
        'file_size' => 'integer',
        'data_types' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }
}

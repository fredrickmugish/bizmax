<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    protected $fillable = ['user_id', 'name', 'phone'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
} 
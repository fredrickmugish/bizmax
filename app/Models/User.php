<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    public function customers()
    {
        return $this->hasMany(Customer::class);
    }
} 
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Business extends Model
{
    protected $fillable = [
        'name', 'type', 'address',
    ];
    // Removed users() belongsToMany relationship and any pivot logic.
}

<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class User extends Authenticatable implements JWTSubject
{
    // REMOVE HasRoles trait
    use HasApiTokens, HasFactory, Notifiable, LogsActivity;

    protected $fillable = [
        'name',
        'phone',
        'password',
        'language',
        'currency',
        'timezone',
        'is_active',
        'phone_verified_at',
        'business_id',
        'role',
        'password_reset_token',
        'password_reset_token_expires_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'password_reset_token',
        'password_reset_token_expires_at',
    ];

    protected $casts = [
        'phone_verified_at' => 'datetime',
        'is_active' => 'boolean',
        'password' => 'hashed',
        'password_reset_token_expires_at' => 'datetime',
    ];

    // JWT Methods
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [
            'business_id' => $this->business_id,
            'language' => $this->language,
            'currency' => $this->currency,
            'role' => $this->role, // Get role directly from the 'role' column
        ];
    }

    // Activity Log
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'email', 'business_name', 'business_type']) // Ensure these match your actual fillable fields or user attributes
            ->logOnlyDirty();
    }

    // Custom Role Helper Methods (ADDED FOR MANUAL ROLE MANAGEMENT)
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isOwner(): bool
    {
        return $this->role === 'owner';
    }

    public function isSalesperson(): bool
    {
        return $this->role === 'salesperson';
    }

    public function hasAnyRole(array $roles): bool
    {
        return in_array($this->role, $roles);
    }

    // Relationships
    public function inventoryItems()
    {
        return $this->hasMany(InventoryItem::class);
    }

    public function businessRecords()
    {
        return $this->hasMany(BusinessRecord::class);
    }

    public function notes()
    {
        return $this->hasMany(Note::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function backups()
    {
        return $this->hasMany(Backup::class);
    }

    public function business()
    {
        return $this->belongsTo(Business::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeByLanguage($query, $language)
    {
        return $query->where('language', $language);
    }
}
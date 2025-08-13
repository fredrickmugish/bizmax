<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // 1. Make phone non-nullable and unique
            $table->string('phone')->nullable(false)->unique()->change();

            // 2. Add OTP columns
            $table->string('otp')->nullable();
            $table->timestamp('otp_expires_at')->nullable();

            // 3. Drop email and password columns
            $table->dropColumn(['email', 'email_verified_at', 'password']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // 1. Revert phone column
            $table->string('phone')->nullable()->unique(false)->change();

            // 2. Drop OTP columns
            $table->dropColumn(['otp', 'otp_expires_at']);

            // 3. Re-add email and password columns
            $table->string('email')->unique()->after('name');
            $table->timestamp('email_verified_at')->nullable()->after('email');
            $table->string('password')->after('phone_verified_at');
        });
    }
};
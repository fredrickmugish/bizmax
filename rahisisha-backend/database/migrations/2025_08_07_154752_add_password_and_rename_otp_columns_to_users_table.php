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
            $table->string('password')->after('phone')->nullable();
            $table->renameColumn('otp', 'password_reset_token');
            $table->renameColumn('otp_expires_at', 'password_reset_token_expires_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('password');
            $table->renameColumn('password_reset_token', 'otp');
            $table->renameColumn('password_reset_token_expires_at', 'otp_expires_at');
        });
    }
};

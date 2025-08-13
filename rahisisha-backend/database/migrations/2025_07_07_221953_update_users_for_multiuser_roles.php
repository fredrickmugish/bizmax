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
            $table->unsignedBigInteger('business_id')->nullable()->after('id');
            $table->foreign('business_id')->references('id')->on('businesses')->onDelete('cascade');
            $table->string('role')->default('salesperson')->after('password');
            $table->dropColumn(['business_name', 'business_type', 'business_address']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('business_name')->after('password');
            $table->string('business_type')->default('Duka la Jumla')->after('business_name');
            $table->text('business_address')->nullable()->after('business_type');
            $table->dropForeign(['business_id']);
            $table->dropColumn(['business_id', 'role']);
        });
    }
};

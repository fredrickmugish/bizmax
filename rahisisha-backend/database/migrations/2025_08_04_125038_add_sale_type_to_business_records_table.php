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
        Schema::table('business_records', function (Blueprint $table) {
            $table->string('sale_type')->nullable()->after('is_credit_sale');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('business_records', function (Blueprint $table) {
            $table->dropColumn('sale_type');
        });
    }
};

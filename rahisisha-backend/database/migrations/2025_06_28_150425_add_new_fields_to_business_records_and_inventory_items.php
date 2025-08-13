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
        // Add new fields to business_records table
        Schema::table('business_records', function (Blueprint $table) {
            if (!Schema::hasColumn('business_records', 'cost_of_goods_sold')) {
                $table->decimal('cost_of_goods_sold', 10, 2)->nullable()->after('unit_price');
            }
            if (!Schema::hasColumn('business_records', 'funding_source')) {
                $table->enum('funding_source', ['revenue', 'personal'])->nullable()->after('cost_of_goods_sold');
            }
        });

        // Add new fields to inventory_items table
        Schema::table('inventory_items', function (Blueprint $table) {
            if (!Schema::hasColumn('inventory_items', 'wholesale_price')) {
                $table->decimal('wholesale_price', 10, 2)->nullable()->after('buying_price');
            }
            if (!Schema::hasColumn('inventory_items', 'retail_price')) {
                $table->decimal('retail_price', 10, 2)->nullable()->after('wholesale_price');
            }
            if (!Schema::hasColumn('inventory_items', 'unit_dimensions')) {
                $table->string('unit_dimensions')->nullable()->after('unit');
            }
            if (!Schema::hasColumn('inventory_items', 'unit_quantity')) {
                $table->decimal('unit_quantity', 10, 3)->default(1.0)->after('unit_dimensions');
            }
        });

        // Add indexes for better performance
        Schema::table('business_records', function (Blueprint $table) {
            if (!Schema::hasIndex('business_records', 'business_records_funding_source_index')) {
                $table->index(['user_id', 'funding_source'], 'business_records_funding_source_index');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove new fields from business_records table
        Schema::table('business_records', function (Blueprint $table) {
            $table->dropColumn(['cost_of_goods_sold', 'funding_source']);
            $table->dropIndex('business_records_funding_source_index');
        });

        // Remove new fields from inventory_items table
        Schema::table('inventory_items', function (Blueprint $table) {
            $table->dropColumn(['wholesale_price', 'retail_price', 'unit_dimensions', 'unit_quantity']);
        });
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('inventory_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('category')->nullable();
            $table->string('unit')->default('bidhaa');
            $table->decimal('buying_price', 10, 2);
            
            // New pricing structure: wholesale and retail prices
            $table->decimal('wholesale_price', 10, 2)->nullable(); // Jumla price
            $table->decimal('retail_price', 10, 2)->nullable(); // Rejareja price
            $table->decimal('selling_price', 10, 2); // Legacy field for backward compatibility
            
            // Unit dimensions for better product tracking
            $table->string('unit_dimensions')->nullable(); // e.g., "Kg", "Liters", "Pieces"
            $table->decimal('unit_quantity', 10, 3)->default(1.0); // Quantity per unit (e.g., 1 Kg, 2.5 Liters)
            
            $table->integer('current_stock')->default(0);
            $table->integer('minimum_stock')->default(0);
            $table->text('description')->nullable();
            $table->string('barcode')->nullable();
            $table->string('sku')->nullable();
            $table->string('product_image')->nullable(); // Product image URL or path
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'category']);
            $table->index(['user_id', 'is_active']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('inventory_items');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('business_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['sale', 'purchase', 'expense']);
            $table->string('description');
            $table->decimal('amount', 10, 2); // For sales: paid amount (income)
            $table->date('date');
            $table->string('category')->nullable();
            $table->text('notes')->nullable();
            $table->string('customer_name')->nullable();
            $table->string('supplier_name')->nullable();
            $table->foreignId('product_id')->nullable()->constrained('inventory_items')->onDelete('set null');
            $table->integer('quantity')->nullable();
            $table->decimal('unit_price', 10, 2)->nullable();
            
            // Cost of Goods Sold for accurate profit calculation
            $table->decimal('cost_of_goods_sold', 10, 2)->nullable();
            
            // Funding source for purchases (revenue vs personal money)
            $table->enum('funding_source', ['revenue', 'personal'])->nullable();
            
            // Credit management fields
            $table->boolean('is_credit_sale')->default(false);
            $table->decimal('total_amount', 10, 2)->nullable(); // Total sale amount for credit sales
            $table->decimal('amount_paid', 10, 2)->nullable(); // Amount actually paid
            $table->decimal('debt_amount', 10, 2)->nullable(); // Remaining debt
            $table->enum('payment_status', ['pending', 'partial', 'paid'])->default('paid');
            $table->date('due_date')->nullable();
            $table->string('reference_number')->nullable();
            
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'type']);
            $table->index(['user_id', 'date']);
            $table->index(['user_id', 'is_credit_sale']);
            $table->index(['user_id', 'funding_source']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('business_records');
    }
};

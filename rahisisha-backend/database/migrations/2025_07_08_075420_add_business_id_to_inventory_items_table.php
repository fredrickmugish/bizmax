<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('inventory_items', function (Blueprint $table) {
            $table->unsignedBigInteger('business_id')->nullable()->after('user_id');
            $table->foreign('business_id')->references('id')->on('businesses')->onDelete('cascade');
        });

        // Update existing inventory items to link them to the correct business
        $users = DB::table('users')->select('id', 'business_id')->get();
        
        foreach ($users as $user) {
            if ($user->business_id) {
                // Update all inventory items for this user to have the same business_id
                DB::table('inventory_items')
                    ->where('user_id', $user->id)
                    ->update(['business_id' => $user->business_id]);
            }
        }

        // Add index for better performance
        Schema::table('inventory_items', function (Blueprint $table) {
            $table->index(['business_id', 'category']);
            $table->index(['business_id', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('inventory_items', function (Blueprint $table) {
            $table->dropForeign(['business_id']);
            $table->dropIndex(['business_id', 'category']);
            $table->dropIndex(['business_id', 'is_active']);
            $table->dropColumn('business_id');
        });
    }
};

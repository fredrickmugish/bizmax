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
        Schema::table('business_records', function (Blueprint $table) {
            // UNCOMMENT THESE LINES to actually add the 'business_id' column
            // Check if the column does not already exist before adding
            if (!Schema::hasColumn('business_records', 'business_id')) {
                $table->unsignedBigInteger('business_id')->nullable()->after('user_id');
                // Make sure the 'businesses' table exists before adding foreign key
                if (Schema::hasTable('businesses')) {
                    $table->foreign('business_id')->references('id')->on('businesses')->onDelete('cascade');
                }
            }
        });

        // Update existing records to link them to the correct business
        // This part runs AFTER the column is confirmed to be added
        $users = DB::table('users')->select('id', 'business_id')->get();
        foreach ($users as $user) {
            if ($user->business_id) {
                DB::table('business_records')
                    ->where('user_id', $user->id)
                    ->update(['business_id' => $user->business_id]);
            }
        }

        // Add index for better performance
        // This part runs AFTER the column is confirmed to be added and updated
        Schema::table('business_records', function (Blueprint $table) {
            // Ensure the column exists before trying to add indexes
            if (Schema::hasColumn('business_records', 'business_id')) {
                $table->index(['business_id', 'type']);
                $table->index(['business_id', 'date']);
                $table->index(['business_id', 'is_credit_sale']);
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('business_records', function (Blueprint $table) {
            // Only drop if the foreign key constraint exists and column exists
            if (Schema::hasColumn('business_records', 'business_id')) {
                if (Schema::getConnection()->getDoctrineSchemaManager()->introspectTable('business_records')->hasForeignKey('business_records_business_id_foreign')) {
                    $table->dropForeign(['business_id']);
                }
            }
            // Only drop indexes if they exist
            if (Schema::getConnection()->getDoctrineSchemaManager()->introspectTable('business_records')->hasIndex('business_records_business_id_type_index')) {
                $table->dropIndex(['business_id', 'type']);
            }
            if (Schema::getConnection()->getDoctrineSchemaManager()->introspectTable('business_records')->hasIndex('business_records_business_id_date_index')) {
                $table->dropIndex(['business_id', 'date']);
            }
            if (Schema::getConnection()->getDoctrineSchemaManager()->introspectTable('business_records')->hasIndex('business_records_business_id_is_credit_sale_index')) {
                $table->dropIndex(['business_id', 'is_credit_sale']);
            }
            // Drop the column itself
            if (Schema::hasColumn('business_records', 'business_id')) {
                $table->dropColumn('business_id');
            }
        });
    }
};
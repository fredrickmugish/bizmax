<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('backups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('filename');
            $table->string('file_path');
            $table->bigInteger('file_size')->nullable();
            $table->enum('backup_type', ['manual', 'automatic'])->default('manual');
            $table->enum('status', ['pending', 'completed', 'failed'])->default('pending');
            $table->json('data_types')->nullable(); // ['inventory', 'records', 'settings']
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('backups');
    }
};

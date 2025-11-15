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
        Schema::create('delivery_proofs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->string('image_path');
            $table->string('original_filename');
            $table->unsignedInteger('file_size')->nullable();
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('uploaded_by');
            $table->text('notes')->nullable();
            $table->timestamps();

            // Foreign keys
            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->foreign('uploaded_by')->references('id')->on('users');
            
            // Index
            $table->index('order_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_proofs');
    }
};

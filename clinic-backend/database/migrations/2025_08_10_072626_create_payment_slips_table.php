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
        Schema::create('payment_slips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->onDelete('cascade');
            $table->string('file_name'); // Stored filename
            $table->string('file_path'); // Storage path
            $table->string('original_name'); // Original uploaded filename
            $table->bigInteger('file_size'); // File size in bytes
            $table->string('mime_type'); // MIME type
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->text('admin_notes')->nullable(); // Admin review notes
            $table->timestamp('reviewed_at')->nullable(); // When reviewed
            $table->foreignId('reviewed_by')->nullable()->constrained('users'); // Admin who reviewed
            $table->timestamps();
            
            $table->index(['order_id', 'status']);
            $table->index('status');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_slips');
    }
};

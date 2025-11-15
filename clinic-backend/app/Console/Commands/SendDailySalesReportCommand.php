<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Jobs\SendDailySalesReport;
use Carbon\Carbon;

class SendDailySalesReportCommand extends Command
{
    protected $signature = 'telegram:daily-sales {--date= : Date in Y-m-d format (default: yesterday)}';

    protected $description = 'Send daily sales report via Telegram';

    public function handle()
    {
        $date = $this->option('date') ? 
            Carbon::createFromFormat('Y-m-d', $this->option('date')) : 
            Carbon::yesterday();

        $this->info("Dispatching daily sales report for: " . $date->format('Y-m-d'));
        
        SendDailySalesReport::dispatch($date);
        
        $this->info('Daily sales report job dispatched successfully!');
        
        return 0;
    }
}
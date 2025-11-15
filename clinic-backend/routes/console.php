<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use App\Jobs\SendDailySalesReport;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Daily Sales Report Scheduler
Schedule::job(new SendDailySalesReport())
    ->dailyAt('18:00')
    ->timezone('Asia/Bangkok')
    ->name('daily-sales-report')
    ->withoutOverlapping();

// Low Stock Check Scheduler
Schedule::command('telegram:check-low-stock')
    ->dailyAt('09:00')
    ->timezone('Asia/Bangkok')
    ->name('low-stock-check')
    ->withoutOverlapping();

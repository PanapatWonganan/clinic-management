<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test', function () {
    return '<h1 style="color: red; text-align: center; margin-top: 50px; font-family: Arial;">🎯 TEST WORKS!</h1>';
});

Route::get('/admin-test', function () {
    return view('admin-dashboard');
});

Route::get('/admin', function () {
    return redirect('/admin-test');
}); 
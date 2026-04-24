<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(prepend: [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        ]);

        // Return null from redirectTo on API requests so Authenticate sends a
        // proper 401 JSON instead of trying to redirect to a non-existent
        // `login` named route.
        $middleware->redirectGuestsTo(function ($request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return null;
            }
            return route('admin.login');
        });

        // ปิด CSRF protection สำหรับ API routes และ admin login
        $middleware->validateCsrfTokens(except: [
            'api/*',
            'admin/login'
        ]);

        // เปิดใช้งาน CORS สำหรับ API
        $middleware->web(append: [
            \Illuminate\Http\Middleware\HandleCors::class,
        ]);

        // Register middleware aliases
        $middleware->alias([
            'admin' => \App\Http\Middleware\IsAdmin::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Force JSON responses for unauthenticated API requests. Without this
        // the default Authenticate middleware tries to redirect to a `login`
        // named route (which doesn't exist — we only have admin.login), so
        // a 401 on /api/* ends up as an HTML 500 from RouteNotFoundException.
        $exceptions->shouldRenderJsonWhen(function ($request) {
            return $request->is('api/*') || $request->expectsJson();
        });
    })->create();

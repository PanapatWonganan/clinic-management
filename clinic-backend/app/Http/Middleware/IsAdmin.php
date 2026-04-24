<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class IsAdmin
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Resolve user from whichever guard authenticated the request
        // (sanctum bearer for API, web session for Blade admin).
        $user = $request->user();

        if (!$user || !$user->is_admin) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'message' => 'คุณไม่มีสิทธิ์เข้าถึงระบบหลังบ้าน',
                ], $user ? 403 : 401);
            }

            return redirect()->route('admin.login')
                ->withErrors(['error' => 'คุณไม่มีสิทธิ์เข้าถึงระบบหลังบ้าน']);
        }

        return $next($request);
    }
}

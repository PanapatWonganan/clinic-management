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
        // ตรวจสอบว่า user login แล้วและเป็น admin
        if (!auth()->check() || !auth()->user()->is_admin) {
            // ถ้าเป็น API request ให้ส่ง JSON response
            if ($request->expectsJson()) {
                return response()->json([
                    'message' => 'คุณไม่มีสิทธิ์เข้าถึงระบบหลังบ้าน'
                ], 403);
            }

            // ถ้าเป็น web request ให้ redirect ไป login
            return redirect()->route('admin.login')
                ->withErrors(['error' => 'คุณไม่มีสิทธิ์เข้าถึงระบบหลังบ้าน']);
        }

        return $next($request);
    }
}

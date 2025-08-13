<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @param  string  ...$roles The roles allowed to access this route (e.g., 'admin', 'owner')
     * @return \Symfony\Component\HttpFoundation\Response
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        // First, check if a user is authenticated. If not, return a 401 Unauthorized response.
        if (! $request->user()) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        // Check if the authenticated user's 'role' from the database is among the allowed roles.
        // The hasAnyRole() method is part of the User model we updated to use the 'role' column.
        if (! $request->user()->hasAnyRole($roles)) {
            // If the user's role is not allowed, return a 403 Forbidden response.
            return response()->json(['message' => 'Unauthorized. Access denied for this role.'], 403);
        }

        // If the user is authenticated and has an allowed role, proceed with the request.
        return $next($request);
    }
}
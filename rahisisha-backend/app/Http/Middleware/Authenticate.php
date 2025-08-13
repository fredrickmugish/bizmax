<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request; // Import Request class

class Authenticate extends Middleware
{
    /**
     * Get the path the user should be redirected to when they are not authenticated.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return string|null
     */
    protected function redirectTo(Request $request): ?string // Added type hint for clarity
    {
        if (! $request->expectsJson()) {
            return route('login'); // This is for web routes (e.g., if you have a frontend dashboard)
        }

        // For API requests, return null so the unauthenticated method is called
        // and can return a JSON response.
        return null;
    }

    /**
     * Handle unauthenticated requests for API: return JSON 401.
     */
    protected function unauthenticated($request, array $guards)
    {
        // This method will now be properly called when redirectTo returns null
        // for API requests that are unauthenticated.
        abort(response()->json([
            'message' => 'Unauthenticated.'
        ], 401));
    }
}
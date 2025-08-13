<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Business;
use Illuminate\Support\Facades\Validator;
use Tymon\JWTAuth\Facades\JWTAuth;

class BusinessController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'type' => 'required|string|max:255',
            'address' => 'required|string|max:255', // Make address required
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = JWTAuth::user();
        $business = Business::create([
            'name' => $request->name,
            'type' => $request->type,
            'address' => $request->address, // Save address
        ]);
        // Set the user's business_id directly (single business only)
        $user->business_id = $business->id;
        $user->save();
        return response()->json([
            'success' => true,
            'message' => 'Business created successfully',
            'data' => $business
        ], 201);
    }
}
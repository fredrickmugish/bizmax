<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Business;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Tymon\JWTAuth\Facades\JWTAuth;

class UserManagementController extends Controller
{
    // List all users in the authenticated owner's business
    public function index()
    {
        $user = JWTAuth::user();
        // The middleware 'check.role:admin,owner' on the route will handle this primary authorization.
        // This internal check can remain as a double-check if desired, but is redundant if middleware is applied.
        if ($user->role !== 'owner' && $user->role !== 'admin') { // Added admin check for clarity
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }
        $users = User::where('business_id', $user->business_id)->get();
        return response()->json(['success' => true, 'data' => $users]);
    }

    // Add/invite a new user (salesperson) to the business
    public function store(Request $request)
    {
        $user = JWTAuth::user();
        // The middleware 'check.role:admin,owner' on the route will handle this primary authorization.
        // This internal check can remain as a double-check if desired, but is redundant if middleware is applied.
        if ($user->role !== 'owner' && $user->role !== 'admin') { // Added admin check for clarity
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'language' => 'nullable|string|in:en,sw',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        $newUser = User::create([
            'name' => $request->name,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'language' => $request->language ?? 'sw',
            'currency' => 'TSH',
            'timezone' => 'Africa/Dar_es_Salaam',
            'business_id' => $user->business_id,
            'role' => 'salesperson', // Assign the role directly to the column
        ]);
        // Removed: $newUser->assignRole('salesperson'); // ⭐⭐⭐ REMOVED THIS SPATIE METHOD ⭐⭐⭐
        return response()->json(['success' => true, 'message' => 'User added successfully', 'data' => $newUser], 201);
    }

    // Remove a user from the business
    public function destroy($id)
    {
        $user = JWTAuth::user();
        // The middleware 'check.role:admin,owner' on the route will handle this primary authorization.
        // This internal check can remain as a double-check if desired, but is redundant if middleware is applied.
        if ($user->role !== 'owner' && $user->role !== 'admin') { // Added admin check for clarity
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }
        $targetUser = User::where('business_id', $user->business_id)->where('id', $id)->first();
        if (!$targetUser) {
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }
        if ($targetUser->id === $user->id) {
            return response()->json(['success' => false, 'message' => 'Cannot remove yourself'], 400);
        }
        $targetUser->delete();
        return response()->json(['success' => true, 'message' => 'User removed successfully']);
    }

    // Reset a user's password (owner/admin only)
    public function resetPassword(Request $request, $id)
    {
        $user = JWTAuth::user();
        // The middleware 'check.role:admin,owner' on the route will handle this primary authorization.
        // This internal check can remain as a double-check if desired, but is redundant if middleware is applied.
        if ($user->role !== 'owner' && $user->role !== 'admin') { // Added admin check for clarity
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }
        $targetUser = User::where('business_id', $user->business_id)->where('id', $id)->first();
        if (!$targetUser) {
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }
        if ($targetUser->id === $user->id) {
            return response()->json(['success' => false, 'message' => 'Cannot reset your own password here'], 400);
        }
        $validator = Validator::make($request->all(), [
            'password' => 'required|string|min:6|confirmed',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        $targetUser->password = Hash::make($request->password);
        $targetUser->save();
        return response()->json(['success' => true, 'message' => 'Password reset successfully']);
    }
}
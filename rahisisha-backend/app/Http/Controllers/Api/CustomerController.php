<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Customer;

class CustomerController extends Controller
{
    public function index()
    {
        $user = auth()->user();
        $customers = Customer::where('user_id', $user->id)->get();
        return response()->json(['success' => true, 'data' => $customers]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:255',
        ]);
        $user = auth()->user();
        $customer = Customer::create([
            'name' => $validated['name'],
            'phone' => $validated['phone'] ?? null,
            'user_id' => $user->id,
        ]);
        return response()->json(['success' => true, 'data' => $customer], 201);
    }

    public function show($id)
    {
        $user = auth()->user();
        $customer = Customer::where('id', $id)->where('user_id', $user->id)->first();
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Customer not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $customer]);
    }

    public function update(Request $request, $id)
    {
        $user = auth()->user();
        $customer = Customer::where('id', $id)->where('user_id', $user->id)->first();
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Customer not found'], 404);
        }
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'nullable|string|max:255',
        ]);
        $customer->update($validated);
        return response()->json(['success' => true, 'data' => $customer]);
    }

    public function destroy($id)
    {
        $user = auth()->user();
        $customer = Customer::where('id', $id)->where('user_id', $user->id)->first();
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Customer not found'], 404);
        }
        $customer->delete();
        return response()->json(['success' => true, 'message' => 'Customer deleted']);
    }
} 
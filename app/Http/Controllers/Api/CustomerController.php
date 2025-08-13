<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $customers = $request->user()->customers()->orderBy('created_at', 'desc')->get();
        return response()->json(['success' => true, 'data' => $customers]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:20|unique:customers,phone,NULL,id,user_id,' . $request->user()->id,
        ]);
        $customer = $request->user()->customers()->create($validated);
        return response()->json(['success' => true, 'data' => $customer]);
    }

    public function update(Request $request, Customer $customer)
    {
        if ($customer->user_id !== $request->user()->id) {
            abort(403);
        }
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:20|unique:customers,phone,' . $customer->id . ',id,user_id,' . $request->user()->id,
        ]);
        $customer->update($validated);
        return response()->json(['success' => true, 'data' => $customer]);
    }

    public function destroy(Request $request, Customer $customer)
    {
        if ($customer->user_id !== $request->user()->id) {
            abort(403);
        }
        $customer->delete();
        return response()->json(['success' => true]);
    }
} 
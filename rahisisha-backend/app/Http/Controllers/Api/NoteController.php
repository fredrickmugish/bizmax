<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Note;

class NoteController extends Controller
{
    public function index()
    {
        $notes = auth()->user()->notes()->latest()->get();
        return response()->json(['data' => $notes]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $note = auth()->user()->notes()->create($request->all());

        return response()->json(['data' => $note], 201);
    }

    public function update(Request $request, Note $note)
    {
        // $this->authorize('update', $note); // Temporarily commented out

        $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $note->update($request->all());

        return response()->json(['data' => $note]);
    }

    public function destroy(Note $note)
    {
        // $this->authorize('delete', $note); // Temporarily commented out

        $note->delete();

        return response()->json(null, 204);
    }
}

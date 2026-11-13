<?php

namespace App\Http\Requests;

use App\Enums\StockMovementType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreStockMovementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            'medicine_id' => ['required', 'integer', 'exists:medicines,id'],
            'type' => ['required', Rule::in([StockMovementType::In->value, StockMovementType::Adjustment->value])],
            'quantity' => ['required', 'integer', 'between:-100000,100000'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }
}

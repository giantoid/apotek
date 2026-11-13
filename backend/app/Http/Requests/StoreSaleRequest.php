<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSaleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'items' => ['required', 'array', 'min:1', 'max:100'],
            'items.*.medicine_id' => ['required', 'integer', 'exists:medicines,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:10000'],
            'paid_amount' => ['required', 'integer', 'min:0'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'items.required' => 'Keranjang belanja masih kosong.',
            'items.min' => 'Keranjang belanja masih kosong.',
            'items.*.medicine_id.exists' => 'Obat tidak ditemukan.',
            'items.*.quantity.min' => 'Jumlah obat minimal 1.',
            'paid_amount.required' => 'Jumlah bayar wajib diisi.',
        ];
    }
}

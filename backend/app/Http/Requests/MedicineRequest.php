<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class MedicineRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->isAdmin();
    }

    public function rules(): array
    {
        $medicine = $this->route('medicine');

        return [
            'sku' => ['required', 'string', 'max:50', Rule::unique('medicines', 'sku')->ignore($medicine)],
            'name' => ['required', 'string', 'max:255'],
            'category_id' => ['required', 'exists:categories,id'],
            'supplier_id' => ['nullable', 'exists:suppliers,id'],
            'unit' => ['required', 'string', 'max:30'],
            'price' => ['required', 'integer', 'min:0'],
            'stock' => [$medicine ? 'prohibited' : 'required', 'integer', 'min:0'],
            'min_stock' => ['required', 'integer', 'min:0'],
            'expiry_date' => ['required', 'date'],
            'requires_prescription' => ['boolean'],
        ];
    }

    public function attributes(): array
    {
        return [
            'sku' => 'kode obat',
            'name' => 'nama obat',
            'category_id' => 'kategori',
            'supplier_id' => 'supplier',
            'unit' => 'satuan',
            'price' => 'harga',
            'stock' => 'stok awal',
            'min_stock' => 'stok minimum',
            'expiry_date' => 'tanggal kedaluwarsa',
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['requires_prescription' => $this->boolean('requires_prescription')]);
    }
}

<?php

namespace App\Http\Resources;

use App\Models\Medicine;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Medicine */
class MedicineResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'sku' => $this->sku,
            'name' => $this->name,
            'category' => new CategoryResource($this->whenLoaded('category')),
            'unit' => $this->unit,
            'price' => $this->price,
            'stock' => $this->stock,
            'min_stock' => $this->min_stock,
            'expiry_date' => $this->expiry_date->toDateString(),
            'requires_prescription' => $this->requires_prescription,
            'is_low_stock' => $this->isLowStock(),
            'is_expiring_soon' => $this->isExpiringSoon(),
        ];
    }
}

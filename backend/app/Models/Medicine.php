<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'sku', 'name', 'category_id', 'supplier_id', 'unit', 'price',
    'stock', 'min_stock', 'expiry_date', 'requires_prescription',
])]
class Medicine extends Model
{
    use HasFactory;

    /** Obat dianggap "segera kedaluwarsa" bila tersisa sekian hari atau kurang. */
    public const EXPIRING_SOON_DAYS = 90;

    protected function casts(): array
    {
        return [
            'price' => 'integer',
            'stock' => 'integer',
            'min_stock' => 'integer',
            'expiry_date' => 'date',
            'requires_prescription' => 'boolean',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class);
    }

    public function stockMovements(): HasMany
    {
        return $this->hasMany(StockMovement::class);
    }

    public function isLowStock(): bool
    {
        return $this->stock <= $this->min_stock;
    }

    public function isExpired(): bool
    {
        return $this->expiry_date->lt(today());
    }

    public function isExpiringSoon(): bool
    {
        return $this->expiry_date->lte(today()->addDays(self::EXPIRING_SOON_DAYS));
    }

    public function scopeLowStock(Builder $query): Builder
    {
        return $query->whereColumn('stock', '<=', 'min_stock');
    }

    public function scopeExpiringSoon(Builder $query): Builder
    {
        return $query->whereDate('expiry_date', '<=', today()->addDays(self::EXPIRING_SOON_DAYS));
    }

    public function scopeSearch(Builder $query, ?string $term): Builder
    {
        if (blank($term)) {
            return $query;
        }

        return $query->where(function (Builder $q) use ($term) {
            $q->where('name', 'like', "%{$term}%")
                ->orWhere('sku', 'like', "%{$term}%");
        });
    }
}

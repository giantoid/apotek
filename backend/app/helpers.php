<?php

if (! function_exists('rupiah')) {
    /**
     * Format angka menjadi Rupiah, contoh: 12500 -> "Rp12.500".
     */
    function rupiah(int|float|null $amount): string
    {
        return 'Rp'.number_format((float) $amount, 0, ',', '.');
    }
}

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Dashboard' }} · {{ config('app.name') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="bg-slate-100 font-sans text-slate-800 antialiased">
<div class="flex min-h-screen">
    {{-- Sidebar --}}
    <aside class="hidden w-64 shrink-0 flex-col bg-emerald-900 px-4 py-6 md:flex">
        <a href="{{ route('admin.dashboard') }}" class="mb-8 flex items-center gap-3 px-2">
            <span class="flex h-10 w-10 items-center justify-center rounded-xl bg-white text-xl font-bold text-emerald-700">+</span>
            <span>
                <span class="block text-lg font-semibold text-white">{{ config('app.name') }}</span>
                <span class="block text-xs text-emerald-200">Panel Admin</span>
            </span>
        </a>

        @php
            $menu = [
                ['admin.dashboard', 'admin.dashboard', 'Dashboard', 'M3 12l9-9 9 9M5 10v10h14V10'],
                ['admin.medicines.index', 'admin.medicines.*', 'Data Obat', 'M9 3h6v4H9zM5 7h14v14H5zM12 11v6M9 14h6'],
                ['admin.categories.index', 'admin.categories.*', 'Kategori', 'M4 6h16M4 12h16M4 18h10'],
                ['admin.sales.index', 'admin.sales.*', 'Laporan Penjualan', 'M4 19V5M4 19h16M8 15v-4M12 15V8M16 15v-6'],
            ];
        @endphp
        <nav class="flex-1 space-y-1">
            @foreach ($menu as [$route, $pattern, $label, $icon])
                <a href="{{ route($route) }}" @class(['nav-link', 'active' => request()->routeIs($pattern)])>
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="{{ $icon }}"/></svg>
                    {{ $label }}
                </a>
            @endforeach
        </nav>

        <div class="mt-6 rounded-lg bg-emerald-800/60 p-3">
            <p class="text-sm font-medium text-white">{{ auth()->user()->name }}</p>
            <p class="text-xs text-emerald-200">{{ auth()->user()->role->label() }}</p>
            <form method="POST" action="{{ route('logout') }}" class="mt-2">
                @csrf
                <button class="text-xs font-medium text-emerald-100 underline hover:text-white">Keluar</button>
            </form>
        </div>
    </aside>

    <main class="flex-1 overflow-x-hidden">
        <header class="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-4">
            <div>
                <h1 class="text-xl font-semibold text-slate-900">{{ $title ?? 'Dashboard' }}</h1>
                @isset($subtitle)<p class="text-sm text-slate-500">{{ $subtitle }}</p>@endisset
            </div>
            <div class="flex items-center gap-2">{{ $actions ?? '' }}</div>
        </header>

        <div class="space-y-6 p-6">
            @if (session('success'))
                <div class="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ session('success') }}</div>
            @endif
            @if (session('error'))
                <div class="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">{{ session('error') }}</div>
            @endif
            @if ($errors->any())
                <div class="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
                    <ul class="list-inside list-disc">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
                </div>
            @endif

            {{ $slot }}
        </div>
    </main>
</div>
</body>
</html>

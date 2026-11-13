<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Masuk · {{ config('app.name') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="flex min-h-screen items-center justify-center bg-gradient-to-br from-emerald-700 to-teal-900 p-4 font-sans antialiased">
<div class="w-full max-w-md">
    <div class="mb-6 text-center text-white">
        <span class="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-white text-3xl font-bold text-emerald-700">+</span>
        <h1 class="text-2xl font-semibold">{{ config('app.name') }}</h1>
        <p class="text-sm text-emerald-100">Sistem Informasi Apotek · Panel Admin</p>
    </div>

    <form method="POST" action="{{ route('login') }}" class="card space-y-4 p-6">
        @csrf
        <div>
            <label for="email" class="label">Email</label>
            <input id="email" name="email" type="email" value="{{ old('email', 'admin@apotek.test') }}" class="input" required autofocus>
            @error('email')<p class="mt-1 text-sm text-rose-600">{{ $message }}</p>@enderror
        </div>
        <div>
            <label for="password" class="label">Password</label>
            <input id="password" name="password" type="password" class="input" required>
        </div>
        <label class="flex items-center gap-2 text-sm text-slate-600">
            <input type="checkbox" name="remember" class="rounded border-slate-300 text-emerald-600"> Ingat saya
        </label>
        <button class="btn-primary w-full">Masuk</button>
        <p class="rounded-lg bg-slate-50 p-3 text-center text-xs text-slate-500">
            Akun demo: <strong>admin@apotek.test</strong> / <strong>password</strong>
        </p>
    </form>
</div>
</body>
</html>

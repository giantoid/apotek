<?php

namespace Tests\Feature\Api;

use App\Enums\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_and_receive_token(): void
    {
        $user = User::factory()->create(['email' => 'kasir@apotek.test', 'role' => Role::Kasir]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'kasir@apotek.test',
            'password' => 'password',
            'device_name' => 'test',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'name', 'email', 'role']]])
            ->assertJsonPath('data.user.id', $user->id)
            ->assertJsonPath('data.user.role', 'kasir');
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create(['email' => 'kasir@apotek.test']);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'kasir@apotek.test',
            'password' => 'salah',
            'device_name' => 'test',
        ])->assertUnprocessable()->assertJsonValidationErrors('email');
    }

    public function test_me_and_logout_with_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.email', $user->email);

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertNoContent();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_protected_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/medicines')->assertUnauthorized();
        $this->getJson('/api/v1/dashboard')->assertUnauthorized();
    }
}

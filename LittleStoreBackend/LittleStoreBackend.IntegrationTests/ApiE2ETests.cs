using Xunit;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;

namespace LittleStoreBackend.IntegrationTests;

public sealed class ApiE2ETests(CustomWebApplicationFactory factory) : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Register_login_and_products_flow_succeeds()
    {
        var email = $"user-{Guid.NewGuid():N}@test.local";
        var register = await _client.PostAsJsonAsync(
            "/api/v1/auth/register",
            new { name = "E2E User", email, password = "Pass123!" });
        Assert.True(register.IsSuccessStatusCode);

        var auth = await register.Content.ReadFromJsonAsync<AuthPayload>();
        Assert.NotNull(auth?.AccessToken);

        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);

        var createProduct = await _client.PostAsJsonAsync(
            "/api/v1/products",
            new { name = "E2E Product", description = "For tests", price = 9.99m });
        Assert.True(createProduct.IsSuccessStatusCode);

        var listProducts = await _client.GetAsync("/api/v1/products");
        Assert.True(listProducts.IsSuccessStatusCode);
    }

    private sealed record AuthPayload(
        [property: JsonPropertyName("accessToken")] string AccessToken);
}
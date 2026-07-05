using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"] ?? throw new InvalidOperationException("Jwt:Key is required.");
var jwtIssuer = jwtSection["Issuer"] ?? "little-store";
var jwtAudience = jwtSection["Audience"] ?? "little-store";
var jwtExpiresMinutes = int.Parse(jwtSection["ExpiresInMinutes"] ?? "60");
var refreshExpiresDays = int.Parse(jwtSection["RefreshExpiresInDays"] ?? "7");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

builder.Services.AddOpenApi();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    SeedData(db);
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

// --- Auth ---

app.MapPost("/auth/register", async (RegisterRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Name) ||
        string.IsNullOrWhiteSpace(request.Email) ||
        string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Name, email and password are required." });
    }

    var email = request.Email.Trim().ToLowerInvariant();
    if (await db.Users.AnyAsync(u => u.Email == email))
    {
        return Results.Conflict(new { message = "Email already registered." });
    }

    var user = new User
    {
        Name = request.Name.Trim(),
        Email = email,
        Password = BCrypt.Net.BCrypt.HashPassword(request.Password),
        CreatedAt = DateTime.UtcNow
    };

    db.Users.Add(user);
    await db.SaveChangesAsync();

    var tokens = await CreateTokenPairAsync(db, user, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    return Results.Ok(new AuthResponse(tokens.AccessToken, tokens.RefreshToken, UserDto.FromEntity(user)));
})
.WithTags("Auth")
.WithName("Register");

app.MapPost("/auth/login", async (LoginRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Email and password are required." });
    }

    var email = request.Email.Trim().ToLowerInvariant();
    var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email);
    if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.Password))
    {
        return Results.Unauthorized();
    }

    var tokens = await CreateTokenPairAsync(db, user, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    return Results.Ok(new AuthResponse(tokens.AccessToken, tokens.RefreshToken, UserDto.FromEntity(user)));
})
.WithTags("Auth")
.WithName("Login");

app.MapPost("/auth/refresh", async (RefreshRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.RefreshToken))
    {
        return Results.BadRequest(new { message = "Refresh token is required." });
    }

    var stored = await db.RefreshTokens
        .Include(r => r.User)
        .FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null);

    if (stored is null || stored.ExpiresAt <= DateTime.UtcNow)
    {
        return Results.Unauthorized();
    }

    stored.RevokedAt = DateTime.UtcNow;
    var tokens = await CreateTokenPairAsync(db, stored.User!, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    await db.SaveChangesAsync();

    return Results.Ok(new TokenResponse(tokens.AccessToken, tokens.RefreshToken));
})
.WithTags("Auth")
.WithName("Refresh");

app.MapPost("/auth/logout", async (RefreshRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.RefreshToken))
    {
        return Results.BadRequest(new { message = "Refresh token is required." });
    }

    var stored = await db.RefreshTokens.FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null);
    if (stored is not null)
    {
        stored.RevokedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
    }

    return Results.NoContent();
})
.WithTags("Auth")
.WithName("Logout");

app.MapGet("/auth/me", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var entity = await db.Users.FindAsync(userId.Value);
    if (entity is null) return Results.NotFound();

    return Results.Ok(UserDto.FromEntity(entity));
})
.RequireAuthorization()
.WithTags("Auth")
.WithName("GetProfile");

// --- Products ---

app.MapGet("/products", async (string? search, AppDbContext db) =>
{
    var query = db.Products.AsQueryable();
    if (!string.IsNullOrWhiteSpace(search))
    {
        var term = search.Trim().ToLowerInvariant();
        query = query.Where(p =>
            p.Name.ToLower().Contains(term) ||
            p.Description.ToLower().Contains(term));
    }

    var products = await query.OrderBy(p => p.Name).ToListAsync();
    return Results.Ok(products.Select(ProductDto.FromEntity));
})
.RequireAuthorization()
.WithTags("Products")
.WithName("ListProducts");

app.MapGet("/products/{id:int}", async (int id, AppDbContext db) =>
{
    var product = await db.Products.FindAsync(id);
    return product is null ? Results.NotFound() : Results.Ok(ProductDto.FromEntity(product));
})
.RequireAuthorization()
.WithTags("Products")
.WithName("GetProduct");

app.MapPost("/products", async (ProductRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Name))
    {
        return Results.BadRequest(new { message = "Name is required." });
    }

    var now = DateTime.UtcNow;
    var product = new Product
    {
        Name = request.Name.Trim(),
        Description = request.Description?.Trim() ?? string.Empty,
        Price = request.Price,
        CreatedAt = now,
        UpdatedAt = now
    };

    db.Products.Add(product);
    await db.SaveChangesAsync();
    return Results.Created($"/products/{product.Id}", ProductDto.FromEntity(product));
})
.RequireAuthorization()
.WithTags("Products")
.WithName("CreateProduct");

app.MapPut("/products/{id:int}", async (int id, ProductRequest request, AppDbContext db) =>
{
    var product = await db.Products.FindAsync(id);
    if (product is null) return Results.NotFound();

    if (string.IsNullOrWhiteSpace(request.Name))
    {
        return Results.BadRequest(new { message = "Name is required." });
    }

    product.Name = request.Name.Trim();
    product.Description = request.Description?.Trim() ?? string.Empty;
    product.Price = request.Price;
    product.UpdatedAt = DateTime.UtcNow;
    await db.SaveChangesAsync();

    return Results.Ok(ProductDto.FromEntity(product));
})
.RequireAuthorization()
.WithTags("Products")
.WithName("UpdateProduct");

app.MapDelete("/products/{id:int}", async (int id, AppDbContext db) =>
{
    var product = await db.Products.FindAsync(id);
    if (product is null) return Results.NotFound();

    db.Products.Remove(product);
    await db.SaveChangesAsync();
    return Results.NoContent();
})
.RequireAuthorization()
.WithTags("Products")
.WithName("DeleteProduct");

// --- Cart ---

app.MapGet("/cart", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var items = await db.CartItems
        .Include(c => c.Product)
        .Where(c => c.UserId == userId.Value)
        .OrderBy(c => c.CreatedAt)
        .ToListAsync();

    var dtos = items.Select(CartItemDto.FromEntity).ToList();
    var total = dtos.Sum(i => i.LineTotal);

    return Results.Ok(new CartResponse(dtos, total));
})
.RequireAuthorization()
.WithTags("Cart")
.WithName("GetCart");

app.MapPost("/cart/items", async (AddCartItemRequest request, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    if (request.Quantity <= 0)
    {
        return Results.BadRequest(new { message = "Quantity must be greater than zero." });
    }

    var product = await db.Products.FindAsync(request.ProductId);
    if (product is null) return Results.NotFound(new { message = "Product not found." });

    var existing = await db.CartItems
        .Include(c => c.Product)
        .FirstOrDefaultAsync(c => c.UserId == userId.Value && c.ProductId == request.ProductId);

    if (existing is not null)
    {
        existing.Quantity += request.Quantity;
        await db.SaveChangesAsync();
        return Results.Ok(CartItemDto.FromEntity(existing));
    }

    var item = new CartItem
    {
        UserId = userId.Value,
        ProductId = request.ProductId,
        Quantity = request.Quantity,
        CreatedAt = DateTime.UtcNow
    };

    db.CartItems.Add(item);
    await db.SaveChangesAsync();
    await db.Entry(item).Reference(c => c.Product).LoadAsync();

    return Results.Created($"/cart/items/{item.Id}", CartItemDto.FromEntity(item));
})
.RequireAuthorization()
.WithTags("Cart")
.WithName("AddCartItem");

app.MapPut("/cart/items/{id:int}", async (int id, UpdateCartItemRequest request, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    if (request.Quantity <= 0)
    {
        return Results.BadRequest(new { message = "Quantity must be greater than zero." });
    }

    var item = await db.CartItems
        .Include(c => c.Product)
        .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId.Value);

    if (item is null) return Results.NotFound();

    item.Quantity = request.Quantity;
    await db.SaveChangesAsync();

    return Results.Ok(CartItemDto.FromEntity(item));
})
.RequireAuthorization()
.WithTags("Cart")
.WithName("UpdateCartItem");

app.MapDelete("/cart/items/{id:int}", async (int id, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var item = await db.CartItems.FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId.Value);
    if (item is null) return Results.NotFound();

    db.CartItems.Remove(item);
    await db.SaveChangesAsync();
    return Results.NoContent();
})
.RequireAuthorization()
.WithTags("Cart")
.WithName("RemoveCartItem");

app.MapDelete("/cart", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var items = await db.CartItems.Where(c => c.UserId == userId.Value).ToListAsync();
    db.CartItems.RemoveRange(items);
    await db.SaveChangesAsync();
    return Results.NoContent();
})
.RequireAuthorization()
.WithTags("Cart")
.WithName("ClearCart");

// --- Orders ---

app.MapGet("/orders", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var orders = await db.Orders
        .Where(o => o.UserId == userId.Value)
        .OrderByDescending(o => o.CreatedAt)
        .ToListAsync();

    return Results.Ok(orders.Select(OrderSummaryDto.FromEntity));
})
.RequireAuthorization()
.WithTags("Orders")
.WithName("ListOrders");

app.MapGet("/orders/{id:int}", async (int id, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var order = await db.Orders
        .Include(o => o.Items)
        .FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId.Value);

    if (order is null) return Results.NotFound();

    return Results.Ok(OrderDetailDto.FromEntity(order));
})
.RequireAuthorization()
.WithTags("Orders")
.WithName("GetOrder");

app.MapPost("/orders/checkout", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var cartItems = await db.CartItems
        .Include(c => c.Product)
        .Where(c => c.UserId == userId.Value)
        .ToListAsync();

    if (cartItems.Count == 0)
    {
        return Results.BadRequest(new { message = "Cart is empty." });
    }

    var total = cartItems.Sum(i => i.Product!.Price * i.Quantity);
    var order = new Order
    {
        UserId = userId.Value,
        Total = total,
        Status = "Completed",
        CreatedAt = DateTime.UtcNow
    };

    foreach (var item in cartItems)
    {
        order.Items.Add(new OrderItem
        {
            ProductId = item.ProductId,
            ProductName = item.Product!.Name,
            Quantity = item.Quantity,
            UnitPrice = item.Product.Price
        });
    }

    db.Orders.Add(order);
    db.CartItems.RemoveRange(cartItems);
    await db.SaveChangesAsync();

    return Results.Ok(OrderDetailDto.FromEntity(order));
})
.RequireAuthorization()
.WithTags("Orders")
.WithName("Checkout");

// --- Favorites ---

app.MapGet("/favorites", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var favorites = await db.Favorites
        .Include(f => f.Product)
        .Where(f => f.UserId == userId.Value)
        .OrderByDescending(f => f.CreatedAt)
        .ToListAsync();

    return Results.Ok(favorites.Select(f => ProductDto.FromEntity(f.Product!)));
})
.RequireAuthorization()
.WithTags("Favorites")
.WithName("ListFavorites");

app.MapGet("/favorites/{productId:int}", async (int productId, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var exists = await db.Favorites.AnyAsync(f =>
        f.UserId == userId.Value && f.ProductId == productId);

    return Results.Ok(new { isFavorite = exists });
})
.RequireAuthorization()
.WithTags("Favorites")
.WithName("CheckFavorite");

app.MapPost("/favorites", async (AddFavoriteRequest request, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var product = await db.Products.FindAsync(request.ProductId);
    if (product is null) return Results.NotFound(new { message = "Product not found." });

    var exists = await db.Favorites.AnyAsync(f =>
        f.UserId == userId.Value && f.ProductId == request.ProductId);

    if (exists)
    {
        return Results.Conflict(new { message = "Product already in favorites." });
    }

    var favorite = new Favorite
    {
        UserId = userId.Value,
        ProductId = request.ProductId,
        CreatedAt = DateTime.UtcNow
    };

    db.Favorites.Add(favorite);
    await db.SaveChangesAsync();

    return Results.Created($"/favorites/{request.ProductId}", ProductDto.FromEntity(product));
})
.RequireAuthorization()
.WithTags("Favorites")
.WithName("AddFavorite");

app.MapDelete("/favorites/{productId:int}", async (int productId, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var favorite = await db.Favorites.FirstOrDefaultAsync(f =>
        f.UserId == userId.Value && f.ProductId == productId);

    if (favorite is null) return Results.NotFound();

    db.Favorites.Remove(favorite);
    await db.SaveChangesAsync();
    return Results.NoContent();
})
.RequireAuthorization()
.WithTags("Favorites")
.WithName("RemoveFavorite");

app.Run();

// --- Helpers ---

static int? GetUserId(ClaimsPrincipal user)
{
    var claim = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue(JwtRegisteredClaimNames.Sub);
    return int.TryParse(claim, out var id) ? id : null;
}

static async Task<(string AccessToken, string RefreshToken)> CreateTokenPairAsync(
    AppDbContext db,
    User user,
    string jwtKey,
    string issuer,
    string audience,
    int expiresMinutes,
    int refreshExpiresDays)
{
    var accessToken = GenerateAccessToken(user, jwtKey, issuer, audience, expiresMinutes);
    var refreshToken = GenerateRefreshToken();

    db.RefreshTokens.Add(new RefreshToken
    {
        UserId = user.Id,
        Token = refreshToken,
        ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiresDays),
        RevokedAt = null
    });

    await db.SaveChangesAsync();
    return (accessToken, refreshToken);
}

static string GenerateAccessToken(User user, string jwtKey, string issuer, string audience, int expiresMinutes)
{
    var claims = new[]
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Email, user.Email),
        new Claim(ClaimTypes.Name, user.Name),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
    var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
    var token = new JwtSecurityToken(
        issuer: issuer,
        audience: audience,
        claims: claims,
        expires: DateTime.UtcNow.AddMinutes(expiresMinutes),
        signingCredentials: credentials);

    return new JwtSecurityTokenHandler().WriteToken(token);
}

static string GenerateRefreshToken()
{
    var bytes = new byte[64];
    RandomNumberGenerator.Fill(bytes);
    return Convert.ToBase64String(bytes);
}

static void SeedData(AppDbContext db)
{
    if (db.Products.Any()) return;

    var now = DateTime.UtcNow;
    db.Products.AddRange(
        new Product { Name = "Camiseta Básica", Description = "Camiseta 100% algodão, cores variadas", Price = 49.90m, CreatedAt = now, UpdatedAt = now },
        new Product { Name = "Calça Jeans", Description = "Jeans slim fit, azul escuro", Price = 129.90m, CreatedAt = now, UpdatedAt = now },
        new Product { Name = "Tênis Casual", Description = "Tênis confortável para o dia a dia", Price = 199.90m, CreatedAt = now, UpdatedAt = now },
        new Product { Name = "Mochila Urbana", Description = "Mochila com compartimento para notebook", Price = 159.90m, CreatedAt = now, UpdatedAt = now },
        new Product { Name = "Boné Esportivo", Description = "Boné ajustável, tecido respirável", Price = 39.90m, CreatedAt = now, UpdatedAt = now },
        new Product { Name = "Relógio Digital", Description = "Relógio resistente à água", Price = 89.90m, CreatedAt = now, UpdatedAt = now },
        new Product { Name = "Fone Bluetooth", Description = "Fone sem fio com cancelamento de ruído", Price = 249.90m, CreatedAt = now, UpdatedAt = now },
        new Product { Name = "Garrafa Térmica", Description = "Mantém bebidas quentes ou frias por 12h", Price = 59.90m, CreatedAt = now, UpdatedAt = now }
    );
    db.SaveChanges();
}

// --- Entities ---

class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Favorite> Favorites => Set<Favorite>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Email).IsUnique();
        });

        modelBuilder.Entity<CartItem>(e =>
        {
            e.HasIndex(c => new { c.UserId, c.ProductId }).IsUnique();
            e.HasOne(c => c.User).WithMany().HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(c => c.Product).WithMany().HasForeignKey(c => c.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Order>(e =>
        {
            e.HasOne(o => o.User).WithMany().HasForeignKey(o => o.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasMany(o => o.Items).WithOne(i => i.Order).HasForeignKey(i => i.OrderId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.HasOne(r => r.User).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(r => r.Token).IsUnique();
        });

        modelBuilder.Entity<Favorite>(e =>
        {
            e.HasIndex(f => new { f.UserId, f.ProductId }).IsUnique();
            e.HasOne(f => f.User).WithMany().HasForeignKey(f => f.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(f => f.Product).WithMany().HasForeignKey(f => f.ProductId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}

class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

class CartItem
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public int ProductId { get; set; }
    public Product? Product { get; set; }
    public int Quantity { get; set; }
    public DateTime CreatedAt { get; set; }
}

class Order
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public decimal Total { get; set; }
    public string Status { get; set; } = "Pending";
    public DateTime CreatedAt { get; set; }
    public List<OrderItem> Items { get; set; } = [];
}

class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public Order? Order { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

class RefreshToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}

class Favorite
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public int ProductId { get; set; }
    public Product? Product { get; set; }
    public DateTime CreatedAt { get; set; }
}

// --- DTOs ---

record RegisterRequest(string Name, string Email, string Password);
record LoginRequest(string Email, string Password);
record RefreshRequest([property: JsonPropertyName("refreshToken")] string RefreshToken);
record ProductRequest(string Name, string? Description, decimal Price);
record AddCartItemRequest(int ProductId, int Quantity);
record UpdateCartItemRequest(int Quantity);
record AddFavoriteRequest(int ProductId);

record AuthResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken,
    UserDto User);

record TokenResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken);

record UserDto(int Id, string Name, string Email, DateTime CreatedAt)
{
    public static UserDto FromEntity(User user) =>
        new(user.Id, user.Name, user.Email, user.CreatedAt);
}

record ProductDto(int Id, string Name, string Description, decimal Price, DateTime CreatedAt, DateTime UpdatedAt)
{
    public static ProductDto FromEntity(Product product) =>
        new(product.Id, product.Name, product.Description, product.Price, product.CreatedAt, product.UpdatedAt);
}

record CartItemDto(int Id, int ProductId, string ProductName, string Description, decimal UnitPrice, int Quantity, decimal LineTotal)
{
    public static CartItemDto FromEntity(CartItem item)
    {
        var price = item.Product?.Price ?? 0;
        return new(
            item.Id,
            item.ProductId,
            item.Product?.Name ?? string.Empty,
            item.Product?.Description ?? string.Empty,
            price,
            item.Quantity,
            price * item.Quantity);
    }
}

record CartResponse(IReadOnlyList<CartItemDto> Items, decimal Total);

record OrderSummaryDto(int Id, decimal Total, string Status, DateTime CreatedAt)
{
    public static OrderSummaryDto FromEntity(Order order) =>
        new(order.Id, order.Total, order.Status, order.CreatedAt);
}

record OrderItemDto(int Id, int ProductId, string ProductName, int Quantity, decimal UnitPrice, decimal LineTotal)
{
    public static OrderItemDto FromEntity(OrderItem item) =>
        new(item.Id, item.ProductId, item.ProductName, item.Quantity, item.UnitPrice, item.UnitPrice * item.Quantity);
}

record OrderDetailDto(int Id, decimal Total, string Status, DateTime CreatedAt, IReadOnlyList<OrderItemDto> Items)
{
    public static OrderDetailDto FromEntity(Order order) =>
        new(order.Id, order.Total, order.Status, order.CreatedAt, order.Items.Select(OrderItemDto.FromEntity).ToList());
}

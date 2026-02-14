using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();
builder.Services.AddDbContext<UserDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

app.MapGet("/hello", () => "Hello World!")
    .WithName("HelloWorld");


// User APIs
app.MapPost("/users", async (CreateUserRequest request, UserDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.UserName))
        return Results.BadRequest("UserName cannot be empty");

    var user = new User { UserName = request.UserName };
    db.Users.Add(user);
    await db.SaveChangesAsync();

    return Results.Created($"/users/{user.Id}", new { user.Id, user.UserName });
})
.WithName("CreateUser")
.WithOpenApi();

app.MapGet("/users", async (UserDbContext db) =>
{
    var users = await db.Users.ToListAsync();
    return Results.Ok(users);
})
.WithName("GetAllUsers")
.WithOpenApi();


app.MapGet("/users/{id}", async (int id, UserDbContext db) =>
{
    var user = await db.Users.FindAsync(id);
    return user is not null ? Results.Ok(user) : Results.NotFound();
}).WithName("GetUserById")
.WithOpenApi();


app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}

record CreateUserRequest(string UserName);

class User
{
    public int Id { get; set; }
    public string UserName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

class UserDbContext : DbContext
{
    public UserDbContext(DbContextOptions<UserDbContext> options) : base(options) { }
    public DbSet<User> Users { get; set; }
}

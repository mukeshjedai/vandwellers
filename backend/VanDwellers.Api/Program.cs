using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using VanDwellers.Core.Models;
using VanDwellers.Core.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin());
});

builder.Services.AddVanDwellersCore(builder.Configuration);

var jwtKey = builder.Configuration["Jwt:Key"] ?? "VanDwellers-Dev-Key-Change-In-Production-Min32Chars!";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        };
    });
builder.Services.AddAuthorization();

var app = builder.Build();
var api = app.Services.GetRequiredService<VanDwellersApiService>();
var jwt = app.Services.GetRequiredService<JwtTokenService>();

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/api/health", () => Results.Ok(new { status = "ok", service = "VanDwellers.Api (legacy — use VanDwellers.Functions)" }));

app.MapPost("/api/auth/register", async (RegisterRequest req) =>
{
    try { return Results.Ok(await api.RegisterAsync(req)); }
    catch (ApiValidationException e) { return Results.BadRequest(new { error = e.Message }); }
    catch (ApiConflictException e) { return Results.Conflict(new { error = e.Message }); }
});

app.MapPost("/api/auth/login", async (LoginRequest req) =>
{
    try { return Results.Ok(await api.LoginAsync(req)); }
    catch (ApiUnauthorizedException) { return Results.Unauthorized(); }
});

app.MapGet("/api/auth/me", async (HttpContext http) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    return Results.Ok(await api.GetMeAsync(userId));
}).RequireAuthorization();

app.MapPut("/api/profile", async (ProfileUpdateRequest req, HttpContext http) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    return Results.Ok(await api.UpdateProfileAsync(userId, req));
}).RequireAuthorization();

app.MapPost("/api/profile/photos", async (HttpContext http, IFormFile file) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    if (file.Length == 0) return Results.BadRequest(new { error = "Empty file." });
    await using var stream = file.OpenReadStream();
    return Results.Ok(await api.UploadProfilePhotoAsync(userId, stream, file.FileName, file.ContentType));
}).RequireAuthorization();

app.MapGet("/api/users", async (HttpContext http) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    return Results.Ok(await api.ListUsersAsync(userId));
}).RequireAuthorization();

app.MapGet("/api/users/{id}", async (string id) =>
{
    var user = await api.GetUserAsync(id);
    return user == null ? Results.NotFound() : Results.Ok(user);
}).RequireAuthorization();

app.MapGet("/api/conversations", async (HttpContext http) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    return Results.Ok(await api.GetConversationsAsync(userId));
}).RequireAuthorization();

app.MapGet("/api/messages/{otherUserId}", async (string otherUserId, HttpContext http) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    return Results.Ok(await api.GetMessagesAsync(userId, otherUserId));
}).RequireAuthorization();

app.MapPost("/api/messages/{otherUserId}", async (string otherUserId, SendMessageRequest req, HttpContext http) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    try { return Results.Ok(await api.SendTextMessageAsync(userId, otherUserId, req)); }
    catch (ApiValidationException e) { return Results.BadRequest(new { error = e.Message }); }
}).RequireAuthorization();

app.MapPost("/api/messages/{otherUserId}/photo", async (string otherUserId, HttpContext http, IFormFile file) =>
{
    var userId = jwt.GetUserId(http.User);
    if (userId == null) return Results.Unauthorized();
    if (file.Length == 0) return Results.BadRequest(new { error = "Empty file." });
    await using var stream = file.OpenReadStream();
    return Results.Ok(await api.SendPhotoMessageAsync(userId, otherUserId, stream, file.FileName, file.ContentType));
}).RequireAuthorization();

app.Run();

public partial class Program;

using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using VanDwellers.Core.Services;

namespace VanDwellers.Functions;

internal static class HttpFunctionHelpers
{
    public static string? GetUserId(HttpRequest req, JwtTokenService jwt, IConfiguration config)
    {
        var fromContext = jwt.GetUserId(req.HttpContext.User);
        if (!string.IsNullOrEmpty(fromContext)) return fromContext;

        var header = req.Headers.Authorization.ToString();
        if (string.IsNullOrWhiteSpace(header) || !header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            return null;

        var token = header["Bearer ".Length..].Trim();
        try
        {
            var handler = new JwtSecurityTokenHandler();
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                config["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key missing")));
            var principal = handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = config["Jwt:Issuer"],
                ValidAudience = config["Jwt:Audience"],
                IssuerSigningKey = key,
            }, out _);
            return jwt.GetUserId(principal);
        }
        catch
        {
            return null;
        }
    }

    public static IActionResult ToActionResult(Exception ex) => ex switch
    {
        ApiValidationException e => new BadRequestObjectResult(new { error = e.Message }),
        ApiConflictException e => new ConflictObjectResult(new { error = e.Message }),
        ApiUnauthorizedException => new UnauthorizedResult(),
        _ => new ObjectResult(new { error = "Internal server error." })
        {
            StatusCode = StatusCodes.Status500InternalServerError,
        },
    };
}

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Models;
using VanDwellers.Core.Services;

namespace VanDwellers.Functions;

public class AuthFunctions(VanDwellersApiService api, JwtTokenService jwt, IConfiguration config)
{
    [Function("Register")]
    public async Task<IActionResult> Register(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "auth/register")] HttpRequest req)
    {
        try
        {
            var body = await req.ReadFromJsonAsync<RegisterRequest>();
            if (body == null) return new BadRequestObjectResult(new { error = "Invalid request body." });
            return new OkObjectResult(await api.RegisterAsync(body));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("Login")]
    public async Task<IActionResult> Login(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "auth/login")] HttpRequest req)
    {
        try
        {
            var body = await req.ReadFromJsonAsync<LoginRequest>();
            if (body == null) return new BadRequestObjectResult(new { error = "Invalid request body." });
            return new OkObjectResult(await api.LoginAsync(body));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("GetMe")]
    public async Task<IActionResult> GetMe(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "auth/me")] HttpRequest req)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            return new OkObjectResult(await api.GetMeAsync(userId));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }
}

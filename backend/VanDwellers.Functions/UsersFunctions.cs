using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Services;

namespace VanDwellers.Functions;

public class UsersFunctions(VanDwellersApiService api, JwtTokenService jwt, IConfiguration config)
{
    [Function("ListUsers")]
    public async Task<IActionResult> ListUsers(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "users")] HttpRequest req)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            return new OkObjectResult(await api.ListUsersAsync(userId));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("GetUser")]
    public async Task<IActionResult> GetUser(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "users/{id}")] HttpRequest req,
        string id)
    {
        try
        {
            var user = await api.GetUserAsync(id);
            return user == null ? new NotFoundResult() : new OkObjectResult(user);
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }
}

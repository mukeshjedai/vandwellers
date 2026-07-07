using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Services;

namespace VanDwellers.Functions;

public class HomeFunctions(VanDwellersApiService api, JwtTokenService jwt, IConfiguration config)
{
    [Function("ListCampsites")]
    public async Task<IActionResult> ListCampsites(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "campsites")] HttpRequest req)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            return new OkObjectResult(await api.ListCampsitesAsync(userId));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("GetCamperUpdates")]
    public async Task<IActionResult> GetCamperUpdates(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "updates")] HttpRequest req)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            return new OkObjectResult(await api.GetCamperUpdatesAsync(userId));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }
}

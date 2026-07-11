using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Models;
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

    [Function("CreateCampsite")]
    public async Task<IActionResult> CreateCampsite(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "campsites")] HttpRequest req)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();

            CreateCampsiteRequest body;
            List<(Stream Stream, string FileName, string ContentType)> photos = [];

            if (req.HasFormContentType)
            {
                body = new CreateCampsiteRequest(
                    req.Form["title"].ToString(),
                    req.Form["description"].ToString(),
                    ParseDouble(req.Form["latitude"].ToString()),
                    ParseDouble(req.Form["longitude"].ToString()),
                    ParseBool(req.Form["hasToilet"].ToString()),
                    ParseBool(req.Form["hasTap"].ToString()));

                foreach (var file in req.Form.Files)
                {
                    if (file.Length == 0) continue;
                    photos.Add((file.OpenReadStream(), file.FileName, file.ContentType));
                }
            }
            else
            {
                var json = await req.ReadFromJsonAsync<CreateCampsiteRequest>();
                if (json == null) return new BadRequestObjectResult(new { error = "Invalid request body." });
                body = json;
            }

            return new OkObjectResult(await api.CreateCampsiteAsync(userId, body, photos));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    private static double ParseDouble(string value) =>
        double.TryParse(value, out var result) ? result : 0;

    private static bool ParseBool(string value) =>
        bool.TryParse(value, out var result) && result;
}

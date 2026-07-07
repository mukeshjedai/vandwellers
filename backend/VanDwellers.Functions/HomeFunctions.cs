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

    [Function("GetCampsite")]
    public async Task<IActionResult> GetCampsite(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "campsites/{campsiteId}")] HttpRequest req,
        string campsiteId)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            return new OkObjectResult(await api.GetCampsiteAsync(userId, campsiteId));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("UploadCampsitePhoto")]
    public async Task<IActionResult> UploadCampsitePhoto(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "campsites/{campsiteId}/photos")] HttpRequest req,
        string campsiteId)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            if (!req.HasFormContentType) return new BadRequestObjectResult(new { error = "Multipart form required." });
            var file = req.Form.Files.GetFile("file");
            if (file == null || file.Length == 0)
                return new BadRequestObjectResult(new { error = "Empty file." });
            await using var stream = file.OpenReadStream();
            var result = await api.UploadCampsitePhotoAsync(userId, campsiteId, stream, file.FileName, file.ContentType);
            return new OkObjectResult(result);
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

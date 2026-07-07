using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Models;
using VanDwellers.Core.Services;

namespace VanDwellers.Functions;

public class ProfileFunctions(VanDwellersApiService api, JwtTokenService jwt, IConfiguration config)
{
    [Function("UpdateProfile")]
    public async Task<IActionResult> UpdateProfile(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "profile")] HttpRequest req)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            var body = await req.ReadFromJsonAsync<ProfileUpdateRequest>();
            if (body == null) return new BadRequestObjectResult(new { error = "Invalid request body." });
            return new OkObjectResult(await api.UpdateProfileAsync(userId, body));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("UploadProfilePhoto")]
    public async Task<IActionResult> UploadProfilePhoto(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "profile/photos")] HttpRequest req)
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
            var result = await api.UploadProfilePhotoAsync(userId, stream, file.FileName, file.ContentType);
            return new OkObjectResult(result);
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }
}

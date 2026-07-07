using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Models;
using VanDwellers.Core.Services;

namespace VanDwellers.Functions;

public class MessagesFunctions(VanDwellersApiService api, JwtTokenService jwt, IConfiguration config)
{
    [Function("GetConversations")]
    public async Task<IActionResult> GetConversations(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "conversations")] HttpRequest req)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            return new OkObjectResult(await api.GetConversationsAsync(userId));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("GetMessages")]
    public async Task<IActionResult> GetMessages(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "messages/{otherUserId}")] HttpRequest req,
        string otherUserId)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            return new OkObjectResult(await api.GetMessagesAsync(userId, otherUserId));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("SendTextMessage")]
    public async Task<IActionResult> SendTextMessage(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "messages/{otherUserId}")] HttpRequest req,
        string otherUserId)
    {
        try
        {
            var userId = HttpFunctionHelpers.GetUserId(req, jwt, config);
            if (userId == null) return new UnauthorizedResult();
            var body = await req.ReadFromJsonAsync<SendMessageRequest>();
            if (body == null) return new BadRequestObjectResult(new { error = "Invalid request body." });
            return new OkObjectResult(await api.SendTextMessageAsync(userId, otherUserId, body));
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }

    [Function("SendPhotoMessage")]
    public async Task<IActionResult> SendPhotoMessage(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "messages/{otherUserId}/photo")] HttpRequest req,
        string otherUserId)
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
            var result = await api.SendPhotoMessageAsync(userId, otherUserId, stream, file.FileName, file.ContentType);
            return new OkObjectResult(result);
        }
        catch (Exception ex) { return HttpFunctionHelpers.ToActionResult(ex); }
    }
}

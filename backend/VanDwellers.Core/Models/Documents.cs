namespace VanDwellers.Core.Models;

public class UserDocument
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Bio { get; set; } = string.Empty;
    public string VanType { get; set; } = string.Empty;
    public string HomeBase { get; set; } = string.Empty;
    public List<string> PhotoUrls { get; set; } = [];
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class MessageDocument
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ConversationId { get; set; } = string.Empty;
    public string SenderId { get; set; } = string.Empty;
    public string RecipientId { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
}

public record RegisterRequest(
    string Username,
    string Password,
    string? DisplayName,
    string? Bio,
    string? VanType,
    string? HomeBase);

public record LoginRequest(string Username, string Password);

public record ProfileUpdateRequest(
    string DisplayName,
    string Bio,
    string VanType,
    string HomeBase);

public record SendMessageRequest(string Text);

public record UserProfileDto(
    string Id,
    string Username,
    string DisplayName,
    string Bio,
    string VanType,
    string HomeBase,
    List<string> PhotoUrls,
    DateTime CreatedAt);

public record AuthResponse(string Token, UserProfileDto User);

public record ConversationPreviewDto(
    string Id,
    string OtherUserId,
    string OtherUser,
    string LastMessage,
    DateTime UpdatedAt);

public record MessageDto(
    string Id,
    string ConversationId,
    string SenderId,
    string Text,
    DateTime SentAt,
    string? ImageUrl);

public record CampsiteDto(
    string Id,
    string Name,
    string Region,
    string Description,
    double Rating,
    List<string> Amenities,
    double Latitude,
    double Longitude);

public record CampsiteDetailDto(
    string Id,
    string Name,
    string Region,
    string Description,
    double Rating,
    List<string> Amenities,
    double Latitude,
    double Longitude,
    List<string> PhotoUrls);

public record CamperUpdateDto(
    string Id,
    string UserId,
    string UserName,
    string DisplayName,
    string UpdateType,
    string Text,
    string? ImageUrl,
    DateTime Timestamp);

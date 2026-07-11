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

public class CampsiteDocument
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Region { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public double Rating { get; set; } = 4.0;
    public List<string> Amenities { get; set; } = [];
    public bool HasToilet { get; set; }
    public bool HasTap { get; set; }
    public List<string> PhotoUrls { get; set; } = [];
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string CreatedByUserId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
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
    string Title,
    string Region,
    string Description,
    double Rating,
    List<string> Amenities,
    double Latitude,
    double Longitude,
    bool HasToilet,
    bool HasTap,
    List<string> PhotoUrls);

public record CreateCampsiteRequest(
    string Title,
    string Description,
    double Latitude,
    double Longitude,
    bool HasToilet,
    bool HasTap,
    string? Address = null);

public record CamperUpdateDto(
    string Id,
    string UserId,
    string UserName,
    string DisplayName,
    string UpdateType,
    string Text,
    string? ImageUrl,
    DateTime Timestamp);

using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public interface IUserRepository
{
    Task<UserDocument?> GetByUsernameAsync(string username, CancellationToken ct = default);
    Task<UserDocument?> GetByIdAsync(string id, CancellationToken ct = default);
    Task CreateAsync(UserDocument user, CancellationToken ct = default);
    Task UpdateAsync(UserDocument user, CancellationToken ct = default);
    Task<List<UserDocument>> ListExceptAsync(string userId, CancellationToken ct = default);
}

public interface IMessageRepository
{
    Task<List<MessageDocument>> GetConversationAsync(string conversationId, CancellationToken ct = default);
    Task SaveAsync(MessageDocument message, CancellationToken ct = default);
    Task<List<MessageDocument>> GetForUserAsync(string userId, CancellationToken ct = default);
}

public interface IPhotoStorage
{
    Task<string> UploadAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default);
}

public static class ConversationHelper
{
    public static string BuildId(string userA, string userB)
    {
        var ids = new[] { userA, userB }.OrderBy(x => x, StringComparer.Ordinal).ToArray();
        return $"{ids[0]}_{ids[1]}";
    }

    public static string OtherUserId(string conversationId, string currentUserId)
    {
        var parts = conversationId.Split('_', 2, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 2)
            return parts[0] == currentUserId ? parts[1] : parts[0];
        return parts.LastOrDefault() ?? currentUserId;
    }
}

public static class UserMapper
{
    public static UserProfileDto ToDto(UserDocument user) => new(
        user.Id,
        user.Username,
        user.DisplayName,
        user.Bio,
        user.VanType,
        user.HomeBase,
        user.PhotoUrls,
        user.CreatedAt);
}

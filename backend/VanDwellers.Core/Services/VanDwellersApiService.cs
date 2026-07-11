using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public class JwtTokenService
{
    private readonly IConfiguration _config;

    public JwtTokenService(IConfiguration config) => _config = config;

    public string CreateToken(UserDocument user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _config["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key missing")));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id),
            new Claim(ClaimTypes.Name, user.Username),
        };
        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string? GetUserId(ClaimsPrincipal user) =>
        user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}

public class VanDwellersApiService
{
    private readonly IUserRepository _users;
    private readonly IMessageRepository _messages;
    private readonly IPhotoStorage _photos;
    private readonly ICampsiteRepository _campsites;
    private readonly JwtTokenService _jwt;

    public VanDwellersApiService(
        IUserRepository users,
        IMessageRepository messages,
        IPhotoStorage photos,
        ICampsiteRepository campsites,
        JwtTokenService jwt)
    {
        _users = users;
        _messages = messages;
        _photos = photos;
        _campsites = campsites;
        _jwt = jwt;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        var username = request.Username.Trim().ToLowerInvariant();
        if (!Regex.IsMatch(username, @"^[a-z0-9_]{3,20}$"))
            throw new ApiValidationException("Username must be 3-20 chars: letters, numbers, underscores.");
        if (request.Password.Length < 6)
            throw new ApiValidationException("Password must be at least 6 characters.");
        if (await _users.GetByUsernameAsync(username) != null)
            throw new ApiConflictException("Username already taken.");

        var user = new UserDocument
        {
            Username = username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            DisplayName = request.DisplayName?.Trim() ?? username,
            Bio = request.Bio?.Trim() ?? string.Empty,
            VanType = request.VanType?.Trim() ?? string.Empty,
            HomeBase = request.HomeBase?.Trim() ?? string.Empty,
        };
        await _users.CreateAsync(user);
        return new AuthResponse(_jwt.CreateToken(user), UserMapper.ToDto(user));
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        var username = request.Username.Trim().ToLowerInvariant();
        var user = await _users.GetByUsernameAsync(username);
        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new ApiUnauthorizedException();
        return new AuthResponse(_jwt.CreateToken(user), UserMapper.ToDto(user));
    }

    public async Task<UserProfileDto> GetMeAsync(string userId)
    {
        var user = await _users.GetByIdAsync(userId)
            ?? throw new ApiUnauthorizedException();
        return UserMapper.ToDto(user);
    }

    public async Task<UserProfileDto> UpdateProfileAsync(string userId, ProfileUpdateRequest request)
    {
        var user = await _users.GetByIdAsync(userId)
            ?? throw new ApiUnauthorizedException();
        user.DisplayName = request.DisplayName.Trim();
        user.Bio = request.Bio.Trim();
        user.VanType = request.VanType.Trim();
        user.HomeBase = request.HomeBase.Trim();
        await _users.UpdateAsync(user);
        return UserMapper.ToDto(user);
    }

    public async Task<UserProfileDto> UploadProfilePhotoAsync(string userId, Stream stream, string fileName, string contentType)
    {
        var user = await _users.GetByIdAsync(userId)
            ?? throw new ApiUnauthorizedException();
        var url = await _photos.UploadAsync(stream, fileName, contentType);
        user.PhotoUrls.Add(url);
        await _users.UpdateAsync(user);
        return UserMapper.ToDto(user);
    }

    public async Task<IEnumerable<UserProfileDto>> ListUsersAsync(string userId)
    {
        _ = await _users.GetByIdAsync(userId) ?? throw new ApiUnauthorizedException();
        var list = await _users.ListExceptAsync(userId);
        return list.Select(UserMapper.ToDto);
    }

    public async Task<UserProfileDto?> GetUserAsync(string id) =>
        (await _users.GetByIdAsync(id)) is { } user ? UserMapper.ToDto(user) : null;

    public async Task<IEnumerable<CampsiteDto>> ListCampsitesAsync(string userId)
    {
        _ = await _users.GetByIdAsync(userId) ?? throw new ApiUnauthorizedException();
        var userSites = await _campsites.ListAllAsync();
        var merged = CampsiteCatalog.All
            .Concat(userSites.Select(UserMapper.ToDto))
            .ToList();
        return merged;
    }

    public async Task<CampsiteDto> CreateCampsiteAsync(
        string userId,
        CreateCampsiteRequest request,
        IEnumerable<(Stream Stream, string FileName, string ContentType)>? photos = null)
    {
        _ = await _users.GetByIdAsync(userId) ?? throw new ApiUnauthorizedException();
        if (string.IsNullOrWhiteSpace(request.Title))
            throw new ApiValidationException("Title is required.");
        if (request.Latitude is < -90 or > 90 || request.Longitude is < -180 or > 180)
            throw new ApiValidationException("Invalid map coordinates.");

        var photoUrls = new List<string>();
        if (photos != null)
        {
            foreach (var photo in photos)
            {
                try
                {
                    var url = await _photos.UploadAsync(photo.Stream, photo.FileName, photo.ContentType);
                    photoUrls.Add(url);
                }
                finally
                {
                    await photo.Stream.DisposeAsync();
                }
            }
        }

        var campsite = new CampsiteDocument
        {
            Title = request.Title.Trim(),
            Description = request.Description.Trim(),
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            HasToilet = request.HasToilet,
            HasTap = request.HasTap,
            PhotoUrls = photoUrls,
            CreatedByUserId = userId,
            Amenities = BuildAmenities(request.HasToilet, request.HasTap),
        };
        await _campsites.CreateAsync(campsite);
        return UserMapper.ToDto(campsite);
    }

    private static List<string> BuildAmenities(bool hasToilet, bool hasTap)
    {
        var amenities = new List<string> { "Community added" };
        if (hasToilet) amenities.Add("Toilet");
        if (hasTap) amenities.Add("Tap");
        return amenities;
    }

    public async Task<IEnumerable<CamperUpdateDto>> GetCamperUpdatesAsync(string userId)
    {
        _ = await _users.GetByIdAsync(userId) ?? throw new ApiUnauthorizedException();
        var users = await _users.ListExceptAsync(userId);
        var updates = new List<CamperUpdateDto>();

        foreach (var user in users)
        {
            var name = user.DisplayName is { Length: > 0 } ? user.DisplayName : user.Username;
            updates.Add(new CamperUpdateDto(
                $"{user.Id}-joined",
                user.Id,
                user.Username,
                name,
                "joined",
                "Joined Van Dwellers",
                null,
                user.CreatedAt));

            if (!string.IsNullOrWhiteSpace(user.Bio))
            {
                updates.Add(new CamperUpdateDto(
                    $"{user.Id}-bio",
                    user.Id,
                    user.Username,
                    name,
                    "profile",
                    user.Bio,
                    null,
                    user.CreatedAt));
            }

            if (!string.IsNullOrWhiteSpace(user.VanType))
            {
                updates.Add(new CamperUpdateDto(
                    $"{user.Id}-van",
                    user.Id,
                    user.Username,
                    name,
                    "van",
                    $"Van: {user.VanType}",
                    null,
                    user.CreatedAt));
            }

            foreach (var (url, index) in user.PhotoUrls.Select((url, index) => (url, index)))
            {
                updates.Add(new CamperUpdateDto(
                    $"{user.Id}-photo-{index}",
                    user.Id,
                    user.Username,
                    name,
                    "photo",
                    "Shared a new photo",
                    url,
                    user.CreatedAt));
            }
        }

        return updates
            .OrderByDescending(u => u.Timestamp)
            .Take(40);
    }

    public async Task<IEnumerable<ConversationPreviewDto>> GetConversationsAsync(string userId)
    {
        var current = await _users.GetByIdAsync(userId)
            ?? throw new ApiUnauthorizedException();
        var allMessages = await _messages.GetForUserAsync(current.Id);
        var previews = new List<ConversationPreviewDto>();

        foreach (var group in allMessages.GroupBy(m => m.ConversationId))
        {
            var last = group.OrderBy(m => m.SentAt).Last();
            var otherId = ConversationHelper.OtherUserId(group.Key, current.Id);
            var other = await _users.GetByIdAsync(otherId);
            var otherName = other?.DisplayName is { Length: > 0 } dn ? dn : other?.Username ?? "Unknown";
            previews.Add(new ConversationPreviewDto(
                group.Key, otherId, otherName, PreviewText(last), last.SentAt));
        }
        return previews.OrderByDescending(p => p.UpdatedAt);
    }

    public async Task<IEnumerable<MessageDto>> GetMessagesAsync(string userId, string otherUserId)
    {
        var current = await _users.GetByIdAsync(userId)
            ?? throw new ApiUnauthorizedException();
        var conversationId = ConversationHelper.BuildId(current.Id, otherUserId);
        var list = await _messages.GetConversationAsync(conversationId);
        return list.Select(m => new MessageDto(
            m.Id, m.ConversationId, m.SenderId, m.Text, m.SentAt, m.ImageUrl));
    }

    public async Task<MessageDto> SendTextMessageAsync(string userId, string otherUserId, SendMessageRequest request)
    {
        var current = await _users.GetByIdAsync(userId)
            ?? throw new ApiUnauthorizedException();
        if (string.IsNullOrWhiteSpace(request.Text))
            throw new ApiValidationException("Message text required.");

        var message = new MessageDocument
        {
            ConversationId = ConversationHelper.BuildId(current.Id, otherUserId),
            SenderId = current.Id,
            RecipientId = otherUserId,
            Text = request.Text.Trim(),
        };
        await _messages.SaveAsync(message);
        return new MessageDto(message.Id, message.ConversationId, message.SenderId,
            message.Text, message.SentAt, message.ImageUrl);
    }

    public async Task<MessageDto> SendPhotoMessageAsync(
        string userId, string otherUserId, Stream stream, string fileName, string contentType)
    {
        var current = await _users.GetByIdAsync(userId)
            ?? throw new ApiUnauthorizedException();
        var url = await _photos.UploadAsync(stream, fileName, contentType);
        var message = new MessageDocument
        {
            ConversationId = ConversationHelper.BuildId(current.Id, otherUserId),
            SenderId = current.Id,
            RecipientId = otherUserId,
            Text = string.Empty,
            ImageUrl = url,
        };
        await _messages.SaveAsync(message);
        return new MessageDto(message.Id, message.ConversationId, message.SenderId,
            message.Text, message.SentAt, message.ImageUrl);
    }

    private static string PreviewText(MessageDocument message)
    {
        if (!string.IsNullOrEmpty(message.ImageUrl) && string.IsNullOrEmpty(message.Text))
            return "Photo";
        return message.Text;
    }
}

public class ApiValidationException(string message) : Exception(message);
public class ApiConflictException(string message) : Exception(message);
public class ApiUnauthorizedException() : Exception("Unauthorized");

using System.Text.Json;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public class LocalJsonStore : IUserRepository, IMessageRepository
{
    private readonly string _dataDir;
    private readonly SemaphoreSlim _lock = new(1, 1);

    public LocalJsonStore(IConfiguration config)
    {
        _dataDir = config["LocalDataPath"]
            ?? Path.Combine(Path.GetTempPath(), "VanDwellers", "App_Data");
        Directory.CreateDirectory(_dataDir);
    }

    private string UsersPath => Path.Combine(_dataDir, "users.json");
    private string MessagesPath => Path.Combine(_dataDir, "messages.json");

    public async Task<UserDocument?> GetByUsernameAsync(string username, CancellationToken ct = default)
    {
        var users = await ReadUsersAsync(ct);
        return users.FirstOrDefault(u =>
            u.Username.Equals(username, StringComparison.OrdinalIgnoreCase));
    }

    public async Task<UserDocument?> GetByIdAsync(string id, CancellationToken ct = default)
    {
        var users = await ReadUsersAsync(ct);
        return users.FirstOrDefault(u => u.Id == id);
    }

    public async Task CreateAsync(UserDocument user, CancellationToken ct = default)
    {
        var users = await ReadUsersAsync(ct);
        users.Add(user);
        await WriteUsersAsync(users, ct);
    }

    public async Task UpdateAsync(UserDocument user, CancellationToken ct = default)
    {
        var users = await ReadUsersAsync(ct);
        var idx = users.FindIndex(u => u.Id == user.Id);
        if (idx >= 0) users[idx] = user;
        else users.Add(user);
        await WriteUsersAsync(users, ct);
    }

    public async Task<List<UserDocument>> ListExceptAsync(string userId, CancellationToken ct = default)
    {
        var users = await ReadUsersAsync(ct);
        return users.Where(u => u.Id != userId).OrderBy(u => u.DisplayName).ToList();
    }

    public async Task<List<MessageDocument>> GetConversationAsync(string conversationId, CancellationToken ct = default)
    {
        var messages = await ReadMessagesAsync(ct);
        return messages.Where(m => m.ConversationId == conversationId)
            .OrderBy(m => m.SentAt).ToList();
    }

    public async Task SaveAsync(MessageDocument message, CancellationToken ct = default)
    {
        var messages = await ReadMessagesAsync(ct);
        messages.Add(message);
        await WriteMessagesAsync(messages, ct);
    }

    public async Task<List<MessageDocument>> GetForUserAsync(string userId, CancellationToken ct = default)
    {
        var messages = await ReadMessagesAsync(ct);
        return messages.Where(m => m.SenderId == userId || m.RecipientId == userId).ToList();
    }

    private async Task<List<UserDocument>> ReadUsersAsync(CancellationToken ct)
    {
        await _lock.WaitAsync(ct);
        try
        {
            if (!File.Exists(UsersPath)) return [];
            await using var stream = File.OpenRead(UsersPath);
            return await JsonSerializer.DeserializeAsync<List<UserDocument>>(stream, cancellationToken: ct) ?? [];
        }
        finally { _lock.Release(); }
    }

    private async Task WriteUsersAsync(List<UserDocument> users, CancellationToken ct)
    {
        await _lock.WaitAsync(ct);
        try
        {
            await using var stream = File.Create(UsersPath);
            await JsonSerializer.SerializeAsync(stream, users,
                new JsonSerializerOptions { WriteIndented = true }, ct);
        }
        finally { _lock.Release(); }
    }

    private async Task<List<MessageDocument>> ReadMessagesAsync(CancellationToken ct)
    {
        await _lock.WaitAsync(ct);
        try
        {
            if (!File.Exists(MessagesPath)) return [];
            await using var stream = File.OpenRead(MessagesPath);
            return await JsonSerializer.DeserializeAsync<List<MessageDocument>>(stream, cancellationToken: ct) ?? [];
        }
        finally { _lock.Release(); }
    }

    private async Task WriteMessagesAsync(List<MessageDocument> messages, CancellationToken ct)
    {
        await _lock.WaitAsync(ct);
        try
        {
            await using var stream = File.Create(MessagesPath);
            await JsonSerializer.SerializeAsync(stream, messages,
                new JsonSerializerOptions { WriteIndented = true }, ct);
        }
        finally { _lock.Release(); }
    }
}

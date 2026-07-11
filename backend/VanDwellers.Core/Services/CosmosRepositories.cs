using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public class CosmosUserRepository : IUserRepository
{
    private readonly Container _container;

    public CosmosUserRepository(CosmosClient client, IConfiguration config)
    {
        var db = config["Azure:CosmosDb:DatabaseName"] ?? "VanDwellers";
        var container = config["Azure:CosmosDb:UsersContainer"] ?? "users";
        _container = client.GetContainer(db, container);
    }

    public async Task<UserDocument?> GetByUsernameAsync(string username, CancellationToken ct = default)
    {
        var query = new QueryDefinition(
            "SELECT * FROM c WHERE LOWER(c.username) = @username")
            .WithParameter("@username", username.ToLowerInvariant());
        using var iterator = _container.GetItemQueryIterator<UserDocument>(query);
        while (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(ct);
            var item = page.FirstOrDefault();
            if (item != null) return item;
        }
        return null;
    }

    public async Task<UserDocument?> GetByIdAsync(string id, CancellationToken ct = default)
    {
        try
        {
            var response = await _container.ReadItemAsync<UserDocument>(id, new PartitionKey(id), cancellationToken: ct);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task CreateAsync(UserDocument user, CancellationToken ct = default)
    {
        await _container.CreateItemAsync(user, new PartitionKey(user.Id), cancellationToken: ct);
    }

    public async Task UpdateAsync(UserDocument user, CancellationToken ct = default)
    {
        await _container.UpsertItemAsync(user, new PartitionKey(user.Id), cancellationToken: ct);
    }

    public async Task<List<UserDocument>> ListExceptAsync(string userId, CancellationToken ct = default)
    {
        var query = new QueryDefinition("SELECT * FROM c WHERE c.id != @id")
            .WithParameter("@id", userId);
        var results = new List<UserDocument>();
        using var iterator = _container.GetItemQueryIterator<UserDocument>(query);
        while (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(ct);
            results.AddRange(page);
        }
        return results.OrderBy(u => u.DisplayName).ToList();
    }
}

public class CosmosMessageRepository : IMessageRepository
{
    private readonly Container _container;

    public CosmosMessageRepository(CosmosClient client, IConfiguration config)
    {
        var db = config["Azure:CosmosDb:DatabaseName"] ?? "VanDwellers";
        var container = config["Azure:CosmosDb:MessagesContainer"] ?? "messages";
        _container = client.GetContainer(db, container);
    }

    public async Task<List<MessageDocument>> GetConversationAsync(string conversationId, CancellationToken ct = default)
    {
        var query = new QueryDefinition("SELECT * FROM c WHERE c.conversationId = @cid")
            .WithParameter("@cid", conversationId);
        var results = new List<MessageDocument>();
        using var iterator = _container.GetItemQueryIterator<MessageDocument>(query);
        while (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(ct);
            results.AddRange(page);
        }
        return results.OrderBy(m => m.SentAt).ToList();
    }

    public async Task SaveAsync(MessageDocument message, CancellationToken ct = default)
    {
        await _container.CreateItemAsync(message, new PartitionKey(message.ConversationId), cancellationToken: ct);
    }

    public async Task<List<MessageDocument>> GetForUserAsync(string userId, CancellationToken ct = default)
    {
        var query = new QueryDefinition(
            "SELECT * FROM c WHERE c.senderId = @uid OR c.recipientId = @uid")
            .WithParameter("@uid", userId);
        var results = new List<MessageDocument>();
        using var iterator = _container.GetItemQueryIterator<MessageDocument>(query);
        while (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(ct);
            results.AddRange(page);
        }
        return results;
    }
}

public class CosmosCampsiteRepository : ICampsiteRepository
{
    private readonly Container _container;

    public CosmosCampsiteRepository(CosmosClient client, IConfiguration config)
    {
        var db = config["Azure:CosmosDb:DatabaseName"] ?? "VanDwellers";
        var container = config["Azure:CosmosDb:CampsitesContainer"] ?? "campsites";
        _container = client.GetContainer(db, container);
    }

    public async Task<List<CampsiteDocument>> ListAllAsync(CancellationToken ct = default)
    {
        var query = new QueryDefinition("SELECT * FROM c");
        var results = new List<CampsiteDocument>();
        using var iterator = _container.GetItemQueryIterator<CampsiteDocument>(query);
        while (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(ct);
            results.AddRange(page);
        }
        return results.OrderByDescending(c => c.CreatedAt).ToList();
    }

    public async Task CreateAsync(CampsiteDocument campsite, CancellationToken ct = default)
    {
        await _container.CreateItemAsync(campsite, new PartitionKey(campsite.Id), cancellationToken: ct);
    }
}

using System.Text.Json;
using Microsoft.Extensions.Configuration;
using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public class LocalCampsiteRepository : ICampsiteRepository
{
    private readonly string _path;
    private readonly SemaphoreSlim _lock = new(1, 1);

    public LocalCampsiteRepository(IConfiguration config)
    {
        var dataDir = config["LocalDataPath"]
            ?? Path.Combine(Path.GetTempPath(), "VanDwellers", "App_Data");
        Directory.CreateDirectory(dataDir);
        _path = Path.Combine(dataDir, "campsites.json");
    }

    public async Task<List<CampsiteDocument>> ListAllAsync(CancellationToken ct = default)
    {
        await _lock.WaitAsync(ct);
        try
        {
            return await ReadUnsafeAsync(ct);
        }
        finally { _lock.Release(); }
    }

    public async Task CreateAsync(CampsiteDocument campsite, CancellationToken ct = default)
    {
        await _lock.WaitAsync(ct);
        try
        {
            var list = await ReadUnsafeAsync(ct);
            list.Add(campsite);
            await WriteUnsafeAsync(list, ct);
        }
        finally { _lock.Release(); }
    }

    private async Task<List<CampsiteDocument>> ReadUnsafeAsync(CancellationToken ct)
    {
        if (!File.Exists(_path)) return [];
        await using var stream = File.OpenRead(_path);
        return await JsonSerializer.DeserializeAsync<List<CampsiteDocument>>(stream, cancellationToken: ct) ?? [];
    }

    private async Task WriteUnsafeAsync(List<CampsiteDocument> list, CancellationToken ct)
    {
        await using var stream = File.Create(_path);
        await JsonSerializer.SerializeAsync(stream, list,
            new JsonSerializerOptions { WriteIndented = true }, ct);
    }
}

using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace VanDwellers.Core.Services;

public interface ICampsitePhotoRepository
{
    Task<List<string>> GetPhotoUrlsAsync(string campsiteId, CancellationToken ct = default);
    Task AddPhotoAsync(string campsiteId, string photoUrl, CancellationToken ct = default);
}

public class CampsitePhotoStore : ICampsitePhotoRepository
{
    private readonly string _photosPath;
    private readonly SemaphoreSlim _lock = new(1, 1);

    public CampsitePhotoStore(IConfiguration config)
    {
        var dataDir = config["LocalDataPath"]
            ?? Path.Combine(Path.GetTempPath(), "VanDwellers", "App_Data");
        Directory.CreateDirectory(dataDir);
        _photosPath = Path.Combine(dataDir, "campsite_photos.json");
    }

    public async Task<List<string>> GetPhotoUrlsAsync(string campsiteId, CancellationToken ct = default)
    {
        var all = await ReadAllAsync(ct);
        return all.TryGetValue(campsiteId, out var urls) ? urls : [];
    }

    public async Task AddPhotoAsync(string campsiteId, string photoUrl, CancellationToken ct = default)
    {
        var all = await ReadAllAsync(ct);
        if (!all.TryGetValue(campsiteId, out var urls))
        {
            urls = [];
            all[campsiteId] = urls;
        }
        urls.Add(photoUrl);
        await WriteAllAsync(all, ct);
    }

    private async Task<Dictionary<string, List<string>>> ReadAllAsync(CancellationToken ct)
    {
        await _lock.WaitAsync(ct);
        try
        {
            if (!File.Exists(_photosPath)) return new Dictionary<string, List<string>>();
            await using var stream = File.OpenRead(_photosPath);
            return await JsonSerializer.DeserializeAsync<Dictionary<string, List<string>>>(stream, cancellationToken: ct)
                ?? new Dictionary<string, List<string>>();
        }
        finally { _lock.Release(); }
    }

    private async Task WriteAllAsync(Dictionary<string, List<string>> all, CancellationToken ct)
    {
        await _lock.WaitAsync(ct);
        try
        {
            await using var stream = File.Create(_photosPath);
            await JsonSerializer.SerializeAsync(stream, all,
                new JsonSerializerOptions { WriteIndented = true }, ct);
        }
        finally { _lock.Release(); }
    }
}

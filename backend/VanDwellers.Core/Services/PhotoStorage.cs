using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Configuration;

namespace VanDwellers.Core.Services;

public class LocalPhotoStorage : IPhotoStorage
{
    private readonly string _uploadDir;
    private readonly string _publicBaseUrl;

    public LocalPhotoStorage(IConfiguration config)
    {
        _uploadDir = config["LocalUploadPath"]
            ?? Path.Combine(Path.GetTempPath(), "VanDwellers", "uploads");
        Directory.CreateDirectory(_uploadDir);
        _publicBaseUrl = config["PublicBaseUrl"] ?? "http://localhost:7071/api/uploads";
    }

    public async Task<string> UploadAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default)
    {
        var safeName = $"{Guid.NewGuid():N}{Path.GetExtension(fileName)}";
        var path = Path.Combine(_uploadDir, safeName);
        await using var file = File.Create(path);
        await stream.CopyToAsync(file, ct);
        return $"{_publicBaseUrl.TrimEnd('/')}/{safeName}";
    }
}

public class AzureBlobPhotoStorage : IPhotoStorage
{
    private readonly string _connectionString;
    private readonly string _containerName;
    private BlobContainerClient? _container;

    public AzureBlobPhotoStorage(IConfiguration config)
    {
        _connectionString = ResolveConnectionString(config)
            ?? throw new InvalidOperationException("Blob storage connection string missing.");
        _containerName = config["Azure:BlobStorage:ContainerName"] ?? "photos";
    }

    private static string? ResolveConnectionString(IConfiguration config)
    {
        var blob = config["Azure:BlobStorage:ConnectionString"];
        if (!string.IsNullOrWhiteSpace(blob)) return blob;

        var jobs = config["AzureWebJobsStorage"];
        if (!string.IsNullOrWhiteSpace(jobs) && !jobs.Contains("UseDevelopmentStorage", StringComparison.OrdinalIgnoreCase))
            return jobs;

        return null;
    }

    private async Task<BlobContainerClient> GetContainerAsync(CancellationToken ct)
    {
        if (_container != null) return _container;
        var container = new BlobContainerClient(_connectionString, _containerName);
        await container.CreateIfNotExistsAsync(cancellationToken: ct);
        _container = container;
        return container;
    }

    public async Task<string> UploadAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default)
    {
        var container = await GetContainerAsync(ct);
        var blobName = $"{Guid.NewGuid():N}{Path.GetExtension(fileName)}";
        var blob = container.GetBlobClient(blobName);
        await blob.UploadAsync(stream, new BlobHttpHeaders { ContentType = contentType }, cancellationToken: ct);
        return blob.Uri.ToString();
    }
}

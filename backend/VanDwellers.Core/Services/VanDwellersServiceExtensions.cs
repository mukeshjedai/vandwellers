using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace VanDwellers.Core.Services;

public static class VanDwellersServiceExtensions
{
    public static IServiceCollection AddVanDwellersCore(this IServiceCollection services, IConfiguration config)
    {
        services.AddSingleton<JwtTokenService>();
        services.AddSingleton<VanDwellersApiService>();

        var cosmosConnection = config["Azure:CosmosDb:ConnectionString"];
        var blobConnection = ResolveBlobConnectionString(config);
        var useLocalFallback = config.GetValue("Azure:UseLocalFallback", true);

        if (!string.IsNullOrWhiteSpace(cosmosConnection))
        {
            services.AddSingleton(_ => new CosmosClient(cosmosConnection, new CosmosClientOptions
            {
                SerializerOptions = new CosmosSerializationOptions
                {
                    PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase,
                },
            }));
            services.AddSingleton<IUserRepository, CosmosUserRepository>();
            services.AddSingleton<IMessageRepository, CosmosMessageRepository>();
            services.AddSingleton<ICampsiteRepository, CosmosCampsiteRepository>();
        }
        else if (useLocalFallback)
        {
            services.AddSingleton<LocalJsonStore>();
            services.AddSingleton<IUserRepository>(sp => sp.GetRequiredService<LocalJsonStore>());
            services.AddSingleton<IMessageRepository>(sp => sp.GetRequiredService<LocalJsonStore>());
            services.AddSingleton<ICampsiteRepository, LocalCampsiteRepository>();
        }
        else
        {
            throw new InvalidOperationException(
                "Configure Azure:CosmosDb:ConnectionString or set Azure:UseLocalFallback=true.");
        }

        if (!string.IsNullOrWhiteSpace(blobConnection))
        {
            services.AddSingleton<IPhotoStorage, AzureBlobPhotoStorage>();
        }
        else if (useLocalFallback)
        {
            services.AddSingleton<IPhotoStorage, LocalPhotoStorage>();
        }
        else
        {
            throw new InvalidOperationException(
                "Configure Azure:BlobStorage:ConnectionString or set Azure:UseLocalFallback=true.");
        }

        return services;
    }

    private static string? ResolveBlobConnectionString(IConfiguration config)
    {
        var blob = config["Azure:BlobStorage:ConnectionString"];
        if (!string.IsNullOrWhiteSpace(blob)) return blob;

        var jobs = config["AzureWebJobsStorage"];
        if (!string.IsNullOrWhiteSpace(jobs) && !jobs.Contains("UseDevelopmentStorage", StringComparison.OrdinalIgnoreCase))
            return jobs;

        return null;
    }
}

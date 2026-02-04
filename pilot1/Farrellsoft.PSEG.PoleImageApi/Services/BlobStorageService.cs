using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Sas;

namespace Farrellsoft.PSEG.PoleImageApi.Services;

public class BlobStorageService
{
    private const string StorageAccountName = "stpoleappdemoeus2mx01";
    private const string ContainerName = "uploads";
    private readonly BlobContainerClient _containerClient;
    private readonly BlobServiceClient _blobServiceClient;

    public BlobStorageService()
    {
        var credential = new DefaultAzureCredential();
        _blobServiceClient = new BlobServiceClient(
            new Uri($"https://{StorageAccountName}.blob.core.windows.net"),
            credential);
        
        _containerClient = _blobServiceClient.GetBlobContainerClient(ContainerName);
    }

    public async Task<string> UploadImageAsync(byte[] imageBytes, string originalFileName)
    {
        // Generate a random GUID for the blob name, preserving the file extension
        var extension = Path.GetExtension(originalFileName);
        var blobName = $"{Guid.NewGuid()}{extension}";

        var blobClient = _containerClient.GetBlobClient(blobName);

        // Upload the image
        using var stream = new MemoryStream(imageBytes);
        await blobClient.UploadAsync(stream, overwrite: true);

        // Generate a SAS URL with read-only access for 1 hour
        var sasBuilder = new BlobSasBuilder
        {
            BlobContainerName = ContainerName,
            BlobName = blobName,
            Resource = "b", // "b" for blob
            StartsOn = DateTimeOffset.UtcNow.AddMinutes(-5), // Add a 5-minute buffer for clock skew
            ExpiresOn = DateTimeOffset.UtcNow.AddHours(1)
        };

        // Set read-only permissions
        sasBuilder.SetPermissions(BlobSasPermissions.Read);

        // Generate the SAS URI using user delegation key for AAD-based SAS
        var userDelegationKey = await _blobServiceClient.GetUserDelegationKeyAsync(
            startsOn: sasBuilder.StartsOn,
            expiresOn: sasBuilder.ExpiresOn);

        var blobUriBuilder = new BlobUriBuilder(blobClient.Uri)
        {
            Sas = sasBuilder.ToSasQueryParameters(userDelegationKey.Value, StorageAccountName)
        };
        
        return blobUriBuilder.ToUri().ToString();
    }
}

public interface IBlobStorageService
{
    Task<string> UploadImageAsync(byte[] imageBytes, string originalFileName);
}

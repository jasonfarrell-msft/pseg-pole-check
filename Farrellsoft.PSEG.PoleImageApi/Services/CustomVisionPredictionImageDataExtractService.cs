using Azure.Core;
using Azure.Identity;
using Farrellsoft.PSEG.PoleImageApi.Models;
using System.Net.Http.Headers;
using System.Text.Json;

namespace Farrellsoft.PSEG.PoleImageApi.Services
{
    public class CustomVisionPredictionImageDataExtractService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory) : IImageDataExtractService
    {
        private static readonly TokenCredential _credential = new DefaultAzureCredential();
        private static readonly string[] _scopes = ["https://cognitiveservices.azure.com/.default"];
        private static readonly JsonSerializerOptions _jsonOptions = new(JsonSerializerDefaults.Web);

        public async Task<ImageDataExtractResult> ExtractDataAsync(byte[] imageData)
        {
            var endpoint = configuration["VISION_ENDPOINT"]!.TrimEnd('/');
            var projectId = configuration["CUSTOM_VISION_PROJECT_ID"]!;
            var publishedName = configuration["CUSTOM_VISION_PUBLISHED_NAME"]!;

            var url = $"{endpoint}/customvision/v3.0/Prediction/{projectId}/detect/iterations/{publishedName}/image";

            var tokenResult = await _credential.GetTokenAsync(
                new TokenRequestContext(_scopes), CancellationToken.None);

            var client = httpClientFactory.CreateClient();
            using var request = new HttpRequestMessage(HttpMethod.Post, url);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", tokenResult.Token);
            request.Content = new ByteArrayContent(imageData);
            request.Content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");

            using var response = await client.SendAsync(request);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<CustomVisionResponse>(json, _jsonOptions)!;

            var vendorTagPredictions = result.Predictions
                .Where(p => p.TagName.Equals("vendor_tag", StringComparison.OrdinalIgnoreCase) && p.Probability > 0.5)
                .Select(p => new VendorTag(p.Probability))
                .ToList();

            var topStencil = result.Predictions
                .Where(p => p.TagName.Equals("stencil", StringComparison.OrdinalIgnoreCase) && p.Probability > 0.5)
                .OrderByDescending(p => p.Probability)
                .FirstOrDefault();

            Rect? stencilBoundingBox = null;
            if (topStencil?.BoundingBox != null)
            {
                stencilBoundingBox = new Rect(
                    topStencil.BoundingBox.Left,
                    topStencil.BoundingBox.Top,
                    topStencil.BoundingBox.Width,
                    topStencil.BoundingBox.Height);
            }

            return new ImageDataExtractResult(vendorTagPredictions, stencilBoundingBox);
        }

        private record CustomVisionResponse(List<CustomVisionPrediction> Predictions);
        private record CustomVisionPrediction(double Probability, string TagName, CustomVisionBoundingBox? BoundingBox);
        private record CustomVisionBoundingBox(double Left, double Top, double Width, double Height);
    }

    public interface IImageDataExtractService
    {
        Task<ImageDataExtractResult> ExtractDataAsync(byte[] imageData);
    }
}
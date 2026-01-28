using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction;
using Farrellsoft.PSEG.PoleImageApi.Models;

namespace Farrellsoft.PSEG.PoleImageApi.Services
{
    public class CustomVisionPredictionImageDataExtractService(IConfiguration configuration) : IImageDataExtractService
    {
        private CustomVisionPredictionClient? _predictionClient;
        
        CustomVisionPredictionClient GetClient()
        {
            if (_predictionClient != null)
            {
                return _predictionClient;
            }

            var endpoint = configuration["VISION_ENDPOINT"];
            var predictionKey = configuration["VISION_KEY"];

            _predictionClient = new CustomVisionPredictionClient(new ApiKeyServiceClientCredentials(predictionKey))
            {
                Endpoint = endpoint
            };

            return _predictionClient;
        }

        public async Task<ImageDataExtractResult> ExtractDataAsync(byte[] imageData)
        {
            var client = GetClient();

            var projectId = Guid.Parse(configuration["CUSTOM_VISION_PROJECT_ID"]);
            var publishedName = configuration["CUSTOM_VISION_PUBLISHED_NAME"];

            using var imageStream = new MemoryStream(imageData);

            var result = await client.DetectImageAsync(projectId, publishedName, imageStream);

            var vendorTagPredictions = result.Predictions
                .Where(p => p.TagName.Equals("vendor tags", StringComparison.OrdinalIgnoreCase) && p.Probability > 0.5)
                .ToList();

            var topStencilPrediction = result.Predictions
                .Where(p => p.TagName.Equals("stencil", StringComparison.OrdinalIgnoreCase) && p.Probability > 0.5)
                .OrderByDescending(p => p.Probability)
                .FirstOrDefault();

            Rect? stencilBoundingBox = null;
            if (topStencilPrediction != null)
            {
                stencilBoundingBox = new Rect(
                    topStencilPrediction.BoundingBox.Left,
                    topStencilPrediction.BoundingBox.Top,
                    topStencilPrediction.BoundingBox.Width,
                    topStencilPrediction.BoundingBox.Height);
            }

            return new ImageDataExtractResult(vendorTagPredictions.Count, stencilBoundingBox);
        }
    }

    public interface IImageDataExtractService
    {
        Task<ImageDataExtractResult> ExtractDataAsync(byte[] imageData);
    }
}
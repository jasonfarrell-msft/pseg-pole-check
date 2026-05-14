using Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction.Models;
using Farrellsoft.PSEG.PoleVerify.Models;

namespace Farrellsoft.PSEG.PoleVerify.Services;

public class DataExtractionService
{
    public ExtractDataResult ExtractData(ImagePrediction prediction)
    {
        // Check for vendor tags
        var vendorTagPredictions = prediction.Predictions
            .Where(p => p.TagName.Equals("vendor tags", StringComparison.OrdinalIgnoreCase) && p.Probability > 0.5)
            .ToList();

        // Process stencil detections - get the one with highest confidence
        var topStencilPrediction = prediction.Predictions
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

        return new ExtractDataResult
        {
            VendorTagCount = vendorTagPredictions.Count,
            StencilBoundingBox = stencilBoundingBox
        };
    }
}

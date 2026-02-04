using Farrellsoft.PSEG.PoleImageApi.Models;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace Farrellsoft.PSEG.PoleImageApi.Services;

public class AnalyzePoleImageService(IImageDataExtractService dataExtractService, IImageReadService imageReadService, BlobStorageService blobStorageService)
{
    public async Task<PoleImageAnalysisResult> AnalyzeImageAsync(byte[] imageBytes, string fileName)
    {
        // Step 1: Upload the image to blob storage and get the SAS URL
        var imageUrl = await blobStorageService.UploadImageAsync(imageBytes, fileName);

        // Step 2: Extract data from the complete image
        var extractResult = await dataExtractService.ExtractDataAsync(imageBytes);

        string? stencilValue = null;
        double? stencilConfidence = null;

        // Step 2: If a stencil bounding box was found, slice the image and read the stencil
        if (extractResult.StencilBoundingBox != null)
        {
            var stencilImageBytes = SliceImage(imageBytes, extractResult.StencilBoundingBox);
            var stencilResult = await imageReadService.ReadStencilValue(stencilImageBytes);
            stencilValue = stencilResult?.StencilValue;
            stencilConfidence = stencilResult?.Confidence;
        }

        // Step 4: Calculate validity
        var isValid = CalculateValidity(extractResult.VendorTags, stencilValue, fileName);

        // Step 5: Return the results including the image URL
        return new PoleImageAnalysisResult(extractResult.VendorTags, stencilValue, stencilConfidence, isValid, imageUrl);
    }

    private bool CalculateValidity(List<VendorTag> vendorTags, string? stencilValue, string fileName)
    {
        // Rule 1: Must have at least one vendor tag
        if (vendorTags == null || vendorTags.Count == 0)
        {
            return false;
        }

        // Rule 2: Stencil value must match the first portion of the filename
        if (string.IsNullOrWhiteSpace(stencilValue))
        {
            return false;
        }

        // Extract expected stencil from filename (before first underscore)
        var expectedStencil = fileName.Split('_').FirstOrDefault();
        if (string.IsNullOrWhiteSpace(expectedStencil))
        {
            return false;
        }

        // Compare stencil values (case-insensitive)
        return string.Equals(stencilValue.Trim(), expectedStencil.Trim(), StringComparison.OrdinalIgnoreCase);
    }

    private byte[] SliceImage(byte[] imageBytes, Rect boundingBox)
    {
        using var inputStream = new MemoryStream(imageBytes);
        using var image = Image.Load(inputStream);

        // Convert normalized coordinates (0-1) to pixel coordinates
        var x = (int)(boundingBox.Left * image.Width);
        var y = (int)(boundingBox.Top * image.Height);
        var width = (int)(boundingBox.Width * image.Width);
        var height = (int)(boundingBox.Height * image.Height);

        // Ensure coordinates are within bounds
        x = Math.Max(0, Math.Min(x, image.Width));
        y = Math.Max(0, Math.Min(y, image.Height));
        width = Math.Max(0, Math.Min(width, image.Width - x));
        height = Math.Max(0, Math.Min(height, image.Height - y));

        var rectangle = new Rectangle(x, y, width, height);
        image.Mutate(ctx => ctx.Crop(rectangle));

        using var outputStream = new MemoryStream();
        image.SaveAsJpeg(outputStream);
        return outputStream.ToArray();
    }
}

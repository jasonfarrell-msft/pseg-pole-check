using Farrellsoft.PSEG.PoleImageApi.Models;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace Farrellsoft.PSEG.PoleImageApi.Services;

public class AnalyzePoleImageService(IImageDataExtractService dataExtractService, IImageReadService imageReadService)
{
    public async Task<PoleImageAnalysisResult> AnalyzeImageAsync(byte[] imageBytes)
    {
        // Step 1: Extract data from the complete image
        var extractResult = await dataExtractService.ExtractDataAsync(imageBytes);

        string? stencilValue = null;

        // Step 2: If a stencil bounding box was found, slice the image and read the stencil
        if (extractResult.StencilBoundingBox != null)
        {
            var stencilImageBytes = SliceImage(imageBytes, extractResult.StencilBoundingBox);
            var stencilResult = await imageReadService.ReadStencilValue(stencilImageBytes);
            stencilValue = stencilResult?.StencilValue;
        }

        // Step 3: Return the results
        return new PoleImageAnalysisResult(extractResult.VendorTagCount, stencilValue);
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

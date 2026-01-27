using Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction;
using Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction.Models;
using Microsoft.Extensions.Configuration;
using Farrellsoft.PSEG.PoleVerify.Services;

namespace Farrellsoft.PSEG.PoleVerify;

class Program
{
    static async Task Main(string[] args)
    {
        // Build configuration from user secrets
        IConfiguration config = new ConfigurationBuilder()
            .AddUserSecrets<Program>()
            .Build();

        // Get configuration from user secrets
        string? endpoint = config["VISION_ENDPOINT"];
        string? predictionKey = config["VISION_KEY"];
        string? projectId = config["CUSTOM_VISION_PROJECT_ID"];
        string? publishedName = config["CUSTOM_VISION_PUBLISHED_NAME"] ?? "Iteration2";
        string? openAiEndpoint = config["OPENAI_ENDPOINT"];
        
        if (args.Length == 0)
        {
            Console.WriteLine("Error: Please provide the path to a JPG image file.");
            Console.WriteLine("Usage: dotnet run <path-to-image.jpg>");
            return;
        }
        
        string imagePath = args[0];
        
        if (!File.Exists(imagePath))
        {
            Console.WriteLine($"Error: File not found: {imagePath}");
            return;
        }

        // Extract expected stencil ID from filename (format: stencilId_date.ext)
        string fileName = Path.GetFileNameWithoutExtension(imagePath);
        string expectedStencilId = ExtractStencilIdFromFilename(fileName);
        Console.WriteLine($"Expected Stencil ID from filename: {expectedStencilId}");
        Console.WriteLine();

        try
        {
            // Create Custom Vision prediction client
            CustomVisionPredictionClient predictionClient = new CustomVisionPredictionClient(
                new Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction.ApiKeyServiceClientCredentials(predictionKey))
            {
                Endpoint = endpoint
            };

            Console.WriteLine($"Analyzing image: {imagePath}");
            Console.WriteLine($"Using published model: {publishedName}");
            Console.WriteLine("Calling Custom Vision API (Object Detection)...\n");

            // Load and predict with the image file (Object Detection)
            using FileStream stream = new FileStream(imagePath, FileMode.Open, FileAccess.Read);
            ImagePrediction result = predictionClient.DetectImage(
                Guid.Parse(projectId),
                publishedName,
                stream);

            Console.WriteLine("\nPrediction Result:");
            Console.WriteLine(new string('=', 60));

            // Extract data using the service
            var dataExtractionService = new DataExtractionService();
            var extractionResult = dataExtractionService.ExtractData(result);
            
            Console.WriteLine($"Vendor Tags Detected: {extractionResult.VendorTagCount}");
            Console.WriteLine();

            string? extractedStencilValue = null;
            
            if (extractionResult.StencilBoundingBox != null)
            {
                Console.WriteLine("Stencil Detected: Yes");
                
                // Call ImageAnalysisService to extract stencil value
                if (!string.IsNullOrEmpty(openAiEndpoint))
                {
                    var imageAnalysisService = new ImageAnalysisService(openAiEndpoint);
                    var analysisResult = await imageAnalysisService.ExtractStencilValueAsync(imagePath, extractionResult.StencilBoundingBox);
                    extractedStencilValue = analysisResult.StencilValue;
                    Console.WriteLine($"StencilValue: {extractedStencilValue ?? "(Unable to extract)"}");
                }
                else
                {
                    Console.WriteLine("StencilValue: (OPENAI_ENDPOINT not configured)");
                }
            }
            else
            {
                Console.WriteLine("Stencil Detected: No");
                Console.WriteLine("StencilValue: (No stencil detected)");
            }

            // Compare extracted stencil with expected value from filename
            bool stencilMatch = !string.IsNullOrEmpty(extractedStencilValue) && 
                               !string.IsNullOrEmpty(expectedStencilId) &&
                               (extractedStencilValue.Contains(expectedStencilId) || expectedStencilId.Contains(extractedStencilValue));
            Console.WriteLine($"StencilMatch: {(stencilMatch ? "yes" : "no")}");

            Console.WriteLine(new string('=', 60));
        }
        catch (CustomVisionErrorException ex)
        {
            Console.WriteLine($"Custom Vision API Error:");
            Console.WriteLine($"  Status Code: {ex.Response.StatusCode}");
            Console.WriteLine($"  Message: {ex.Message}");
            Console.WriteLine($"  Response: {ex.Response.Content}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
        }
    }

    static string ExtractStencilIdFromFilename(string fileName)
    {
        // Filename format: stencilId_date (e.g., "12345_20260115")
        // Extract the part before the first underscore
        int underscoreIndex = fileName.IndexOf('_');
        if (underscoreIndex > 0)
        {
            return fileName.Substring(0, underscoreIndex);
        }
        // If no underscore found, return the entire filename
        return fileName;
    }
}


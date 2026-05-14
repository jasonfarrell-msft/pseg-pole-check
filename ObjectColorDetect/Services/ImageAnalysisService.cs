using Azure.Identity;
using Azure.AI.OpenAI;
using OpenAI.Chat;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using System.Text.Json;
using Farrellsoft.PSEG.PoleVerify.Models;
using Farrellsoft.PSEG.PoleVerify.Utilities;

namespace Farrellsoft.PSEG.PoleVerify.Services;

public class ImageAnalysisService
{
    private readonly string _endpoint;
    private readonly string _deploymentName = "gpt-5.1-chat-deployment";

    public ImageAnalysisService(string endpoint)
    {
        _endpoint = endpoint;
    }

    public async Task<ImageAnalysisResult> ExtractStencilValueAsync(string imagePath, Rect boundingBox)
    {
        // Load the original image
        using var originalImage = await Image.LoadAsync(imagePath);
        
        // Calculate pixel coordinates from normalized bounding box
        int x = (int)(boundingBox.Left * originalImage.Width);
        int y = (int)(boundingBox.Top * originalImage.Height);
        int width = (int)(boundingBox.Width * originalImage.Width);
        int height = (int)(boundingBox.Height * originalImage.Height);
        
        // Ensure coordinates are within image bounds
        x = Math.Max(0, Math.Min(x, originalImage.Width - 1));
        y = Math.Max(0, Math.Min(y, originalImage.Height - 1));
        width = Math.Min(width, originalImage.Width - x);
        height = Math.Min(height, originalImage.Height - y);
        
        // Crop the image to the bounding box region
        using var croppedImage = originalImage.Clone(ctx => 
            ctx.Crop(new Rectangle(x, y, width, height)));
        
        // Convert cropped image to bytes
        using var memoryStream = new MemoryStream();
        await croppedImage.SaveAsJpegAsync(memoryStream);
        var imageBytes = memoryStream.ToArray();
        
        // Create Azure OpenAI client with DefaultAzureCredential
        var credential = new DefaultAzureCredential();
        var client = new AzureOpenAIClient(new Uri(_endpoint), credential);
        var chatClient = client.GetChatClient(_deploymentName);
        
        // Create the chat message with the image
        var messages = new List<ChatMessage>
        {
            new SystemChatMessage(PromptHelper.StencilExtractionSystemPrompt),
            new UserChatMessage(
                ChatMessageContentPart.CreateImagePart(BinaryData.FromBytes(imageBytes), "image/jpeg"))
        };
        
        // Call the model
        var response = await chatClient.CompleteChatAsync(messages);
        
        var responseText = response.Value.Content.FirstOrDefault()?.Text?.Trim();
        
        // Parse JSON response to extract textResult value
        string? stencilValue = null;
        if (!string.IsNullOrEmpty(responseText))
        {
            try
            {
                using var jsonDoc = JsonDocument.Parse(responseText);
                if (jsonDoc.RootElement.TryGetProperty("textResult", out var textResultElement))
                {
                    stencilValue = textResultElement.GetString();
                }
            }
            catch (JsonException)
            {
                // If JSON parsing fails, use the raw response
                stencilValue = responseText;
            }
        }
        
        return new ImageAnalysisResult
        {
            StencilValue = stencilValue
        };
    }
}

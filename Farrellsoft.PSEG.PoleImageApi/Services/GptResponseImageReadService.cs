using Azure.AI.OpenAI;
using Azure.Identity;
using OpenAI.Chat;
using Farrellsoft.PSEG.PoleImageApi.Utilities;
using Farrellsoft.PSEG.PoleImageApi.Models;
using System.Text.Json;

namespace Farrellsoft.PSEG.PoleImageApi.Services;

public class GptResponseImageReadService(IConfiguration configuration) : IImageReadService
{
    public async Task<StencilReadResult?> ReadStencilValue(byte[] imageBytes)
    {
        var endpoint = configuration["FoundryEndpoint"];
        var deploymentName = configuration["FoundryModelDeploymentName"];

        var credential = new DefaultAzureCredential();
        var client = new AzureOpenAIClient(new Uri(endpoint!), credential);
        var chatClient = client.GetChatClient(deploymentName);

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

        if (string.IsNullOrEmpty(responseText))
        {
            return null;
        }

        // Parse the JSON response
        var jsonDoc = JsonDocument.Parse(responseText);
        var textResultElement = jsonDoc.RootElement.GetProperty("textResult");
        var textResult = textResultElement.ValueKind == JsonValueKind.String
            ? textResultElement.GetString()
            : textResultElement.GetRawText();
        
        double? confidence = null;
        if (jsonDoc.RootElement.TryGetProperty("confidence", out var confidenceElement))
        {
            confidence = confidenceElement.GetDouble();
        }

        if (string.IsNullOrEmpty(textResult))
        {
            return null;
        }

        return new StencilReadResult(textResult, confidence);
    }
}

public interface IImageReadService
{
    Task<StencilReadResult?> ReadStencilValue(byte[] imageBytes);
}

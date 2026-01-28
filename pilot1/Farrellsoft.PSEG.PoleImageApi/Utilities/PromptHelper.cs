namespace Farrellsoft.PSEG.PoleImageApi.Utilities;

public static class PromptHelper
{
    public static string StencilExtractionSystemPrompt => """
        Return the text found in the image given. When you respond so do using the following JSON format:

        {
          "textResult": <extracted value>
        }

        Strip out any non-numeric characters. Only numbers should be returned
        Respond with ONLY this JSON, nothing else
        """;
}

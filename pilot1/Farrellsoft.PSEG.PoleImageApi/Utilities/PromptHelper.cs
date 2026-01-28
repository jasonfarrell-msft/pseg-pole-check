namespace Farrellsoft.PSEG.PoleImageApi.Utilities;

public static class PromptHelper
{
    public static string StencilExtractionSystemPrompt => """
        Return the text found in the image given. When you respond so do using the following JSON format:

        {
          "textResult": <extracted value>,
          "confidence": <confidence score between 0 and 1>
        }

        Strip out any non-numeric characters from textResult. Only numbers should be returned in textResult.
        For confidence, provide a decimal value between 0 and 1 representing how confident you are in your text extraction (1 being most confident, 0 being not confident).
        Respond with ONLY this JSON, nothing else
        """;
}

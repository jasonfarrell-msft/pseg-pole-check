namespace Farrellsoft.PSEG.PoleImageApi.Models;

public record PoleImageAnalysisResult(List<VendorTag> VendorTags, string? StencilValue, double? StencilConfidence, bool IsValid);

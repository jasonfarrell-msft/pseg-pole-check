using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Farrellsoft.PSEG.PoleImageApi.Models;

public record Rect(double Left, double Top, double Width, double Height);

public record ImageDataExtractResult(List<VendorTag> VendorTags, Rect? StencilBoundingBox);
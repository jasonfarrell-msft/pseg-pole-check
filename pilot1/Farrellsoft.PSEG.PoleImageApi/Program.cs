using Farrellsoft.PSEG.PoleImageApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Register application services
builder.Services.AddTransient<AnalyzePoleImageService>();
builder.Services.AddSingleton<BlobStorageService>();
builder.Services.AddSingleton<IImageDataExtractService, CustomVisionPredictionImageDataExtractService>();
builder.Services.AddSingleton<IImageReadService, GptResponseImageReadService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.MapPost("/image/analyze", async (IFormFile file, AnalyzePoleImageService analysisService) =>
{
    if (file == null || file.Length == 0)
    {
        return Results.BadRequest("File is required and must have content.");
    }

    // Read file bytes
    using var memoryStream = new MemoryStream();
    await file.CopyToAsync(memoryStream);
    var imageBytes = memoryStream.ToArray();

    // Analyze the image
    var result = await analysisService.AnalyzeImageAsync(imageBytes, file.FileName);

    return Results.Ok(result);
})
.WithName("AnalyzeImage")
.DisableAntiforgery();

app.Run();

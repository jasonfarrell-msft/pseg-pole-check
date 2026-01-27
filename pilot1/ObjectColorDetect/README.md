# Azure Vision API - Image Analysis

A simple C# console application that calls the Microsoft Azure Computer Vision API to analyze local JPG images using a custom model and prints the formatted JSON response.

## Prerequisites

- .NET 9.0 SDK
- Azure Computer Vision resource (with endpoint and API key)
- Custom trained model (optional - uses 'latest' by default)

## Setup

1. Restore dependencies:

```bash
dotnet restore
```

2. Configure user secrets:

```bash
dotnet user-secrets set "VISION_ENDPOINT" "https://your-resource.cognitiveservices.azure.com/"
dotnet user-secrets set "VISION_KEY" "your-api-key-here"
dotnet user-secrets set "VISION_MODEL_VERSION" "your-custom-model-version"  # Optional, defaults to 'latest'
```

3. Verify your secrets (optional):

```bash
dotnet user-secrets list
```

4. Build the project:

```bash
dotnet build
```

## Usage

Run the application with a path to a JPG image:

```bash
dotnet run path/to/your/image.jpg
```

### Example

```bash
dotnet run /home/user/photos/sample.jpg
```

## Features Analyzed

The program analyzes images with the following features:
- **Caption**: Main description of the image
- **Dense Captions**: Multiple detailed captions for different regions
- **Objects**: Detected objects with bounding boxes
- **Tags**: Identified tags/labels with confidence scores
- **People**: Detected people in the image
- **Smart Crops**: Suggested crop regions
- **Read (OCR)**: Text extraction from the image

## Output

The program outputs:
1. Analysis progress messages
2. Complete JSON response from the Azure Vision API (formatted and indented)

## Error Handling

The application handles:
- Missing environment variables
- File not found errors
- Azure API errors (with status code and error message)
- General exceptions with stack traces

## Dependencies

- `Azure.AI.Vision.ImageAnalysis` (v1.0.0-beta.3)
- `Microsoft.Extensions.Configuration` (v9.0.0)
- `Microsoft.Extensions.Configuration.UserSecrets` (v9.0.0)
- `System.Text.Json` (v9.0.0)

## About User Secrets

User secrets are stored securely on your local machine (not in the repository) at:
- **Linux/macOS**: `~/.microsoft/usersecrets/<UserSecretsId>/secrets.json`
- **Windows**: `%APPDATA%\Microsoft\UserSecrets\<UserSecretsId>\secrets.json`

This keeps your API keys safe and out of source control.

## Custom Models

To use a custom trained model:
1. Train your model in Azure AI Vision Studio
2. Note the model version from your training
3. Set the `VISION_MODEL_VERSION` environment variable to your model version
4. Run the application

If `VISION_MODEL_VERSION` is not set, it defaults to "latest" which uses the most recent production model.

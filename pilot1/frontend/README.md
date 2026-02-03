# PSEG Pole Image Validator

A React single-page application for validating pole images using Azure AI services.

## Features

- **Image Upload**: Select and upload pole images for validation
- **Real-time Analysis**: Submit images to Azure Container Apps endpoint for processing
- **Loading Indicator**: Visual feedback during image analysis
- **Results Display**:
  - Vendor tags with confidence scores
  - Stencil information (expected vs. extracted)
  - Visual validation status (green checkmark or red X)
- **PSEG Branding**: Custom color palette matching PSEG corporate identity

## Project Structure

```
frontend/
├── src/
│   ├── components/
│   │   ├── ImageUpload.jsx    # File upload component
│   │   └── Results.jsx         # Results display component
│   ├── services/
│   │   └── imageService.js     # API service for image analysis
│   ├── App.jsx                 # Main application component
│   ├── App.css                 # Application styles
│   └── main.jsx                # Application entry point
├── index.html                  # HTML template
├── package.json                # Dependencies and scripts
└── vite.config.js             # Vite configuration
```

## Installation

1. Install dependencies:
```bash
npm install
```

## Development

Start the development server:
```bash
npm run dev
```

The application will be available at `http://localhost:3000`

## Build

Create a production build:
```bash
npm run build
```

## Technologies Used

- **React 18**: UI framework
- **Vite**: Build tool and dev server
- **Bootstrap 5**: CSS framework for responsive layout
- **Font Awesome**: Icon library for visual indicators
- **Axios**: HTTP client for API requests

## API Integration

The application submits images to:
```
https://aca-image-api-eus2-mx01.purplesand-57d34aa5.eastus2.azurecontainerapps.io/image/analyze
```

Expected response format:
```json
{
  "vendorTags": [
    { "confidence": 0.99910384 },
    { "confidence": 0.9979025 }
  ],
  "stencilValue": "64343",
  "stencilConfidence": 0.97,
  "isValid": false
}
```

## Usage

1. Click "Select Image File" to choose a pole image
2. The expected stencil is extracted from the filename (first segment before underscore)
3. Click "Analyze Image" to submit for validation
4. View results on the left side:
   - Vendor tags with confidence percentages
   - Expected vs. extracted stencil values
   - Visual validation indicator (✓ or ✗)

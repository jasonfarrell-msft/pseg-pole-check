# Parker History

## Core Context

- Project: pseg-pole-check
- Primary user: Jason Farrell
- Backend stack: .NET 9, ASP.NET Core, Azure Storage Blobs, Azure Identity, Azure Vision/OpenAI-related SDKs, ImageSharp.
- Key path: `Farrellsoft.PSEG.PoleImageApi/`.

## Learnings

### Mission Control API Deployment (2026-05-14)
- API image `mission-control-20260513-1958` deployed to Container Apps `aca-image-api-eus2-mx01` in `rg-pseg-pole-app-eus2-mx01`
- Revision `aca-image-api-eus2-mx01--0000009` active; provisioning state succeeded
- FQDN: `aca-image-api-eus2-mx01.purplesand-57d34aa5.eastus2.azurecontainerapps.io`
- Root route returns 404 (expected); API operational and ready for integration


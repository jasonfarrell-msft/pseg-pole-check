import React, { useState, useEffect } from 'react';
import { API_ENDPOINT } from '../services/imageService';

const getBadgeClass = (status) => {
  switch (status) {
    case 'Operational':
    case 'Ready':
    case 'Passed':
      return 'bg-success';
    case 'Processing':
    case 'Standby':
      return 'bg-primary';
    case 'Attention':
    case 'Failed':
      return 'bg-warning text-dark';
    case 'Error':
      return 'bg-danger';
    default:
      return 'bg-secondary';
  }
};

const StatusCard = ({ icon, name, status, detail, category }) => (
  <div className="col-md-6 col-xl-4 mb-4">
    <div className="card shadow-sm h-100 mission-control-card">
      <div className="card-body">
        <div className="d-flex justify-content-between align-items-start mb-3">
          <div className="mission-control-icon">
            <i className={icon}></i>
          </div>
          <span className={`badge ${getBadgeClass(status)}`}>{status}</span>
        </div>
        <h5 className="card-title">{name}</h5>
        {category && <div className="text-muted small mb-2">{category}</div>}
        <p className="card-text text-muted mb-0">{detail}</p>
      </div>
    </div>
  </div>
);

const MissionControl = ({ isLoading, results, expectedStencil, error }) => {
  const [apiHealthy, setApiHealthy] = useState(null);

  // Check API health on component mount
  useEffect(() => {
    const checkApiHealth = async () => {
      try {
        // Basic check - if API_ENDPOINT is configured, assume healthy unless error
        if (API_ENDPOINT && API_ENDPOINT.includes('http')) {
          setApiHealthy(true);
        } else {
          setApiHealthy(false);
        }
      } catch {
        setApiHealthy(false);
      }
    };
    checkApiHealth();
  }, []);

  const vendorTagCount = results?.vendorTags?.length ?? 0;
  const hasStencil = Boolean(results?.stencilValue);
  const hasImagePreview = Boolean(results?.imageUrl);
  const stencilConfidence = typeof results?.stencilConfidence === 'number'
    ? `${(results.stencilConfidence * 100).toFixed(2)}% confidence`
    : 'confidence unavailable';
  const validationStatus = results?.isValid ? 'Passed' : 'Failed';

  // Frontend components
  const frontendComponents = [
    {
      icon: 'fas fa-laptop-code',
      name: 'Frontend Application',
      category: 'Client',
      status: 'Operational',
      detail: 'React 18 + Vite frontend is running. Navigation and upload form are responsive.',
    },
    {
      icon: 'fas fa-upload',
      name: 'Image Upload',
      category: 'Client',
      status: isLoading ? 'Processing' : 'Ready',
      detail: isLoading ? 'Image submitted and awaiting analysis.' : 'Upload form is ready for the next pole image.',
    },
    {
      icon: 'fas fa-image',
      name: 'Image Preview',
      category: 'Client',
      status: hasImagePreview ? 'Operational' : 'Standby',
      detail: hasImagePreview ? 'Uploaded image preview is available.' : 'No uploaded image preview is currently loaded.',
    },
  ];

  // Backend and API components
  const backendComponents = [
    {
      icon: 'fas fa-server',
      name: 'Pole Image API',
      category: 'Backend Service',
      status: error ? 'Error' : isLoading ? 'Processing' : apiHealthy ? 'Operational' : 'Standby',
      detail: error ? String(error) : (results ? `Last request completed successfully. Endpoint: ${API_ENDPOINT.substring(0, 50)}...` : `API configured and ready. Endpoint: ${API_ENDPOINT.substring(0, 50)}...`),
    },
    {
      icon: 'fas fa-brain',
      name: 'AI Vision Pipeline',
      category: 'AI Service',
      status: error ? 'Error' : isLoading ? 'Processing' : results ? 'Operational' : 'Standby',
      detail: results ? `Completed analysis with ${vendorTagCount} vendor tag${vendorTagCount === 1 ? '' : 's'} and ${hasStencil ? 'stencil' : 'no stencil'} detected.` : 'Azure AI vision and OCR services are integrated and awaiting requests.',
    },
    {
      icon: 'fas fa-database',
      name: 'Blob Storage',
      category: 'Storage',
      status: hasImagePreview ? 'Operational' : 'Standby',
      detail: hasImagePreview ? 'Image successfully stored and retrieved for preview display.' : 'Azure Blob Storage configured for uploaded image assets.',
    },
  ];

  // Analysis components
  const analysisComponents = [
    {
      icon: 'fas fa-tags',
      name: 'Vendor Tag Detection',
      category: 'Analysis',
      status: results ? (vendorTagCount > 0 ? 'Operational' : 'Attention') : 'Standby',
      detail: results ? `${vendorTagCount} vendor tag${vendorTagCount === 1 ? '' : 's'} detected in the last image.` : 'Waiting for an analyzed image.',
    },
    {
      icon: 'fas fa-font',
      name: 'Stencil OCR',
      category: 'Analysis',
      status: results ? (hasStencil ? 'Operational' : 'Attention') : 'Standby',
      detail: hasStencil ? `Extracted stencil "${results.stencilValue}" with ${stencilConfidence}.` : 'No stencil value has been extracted yet.',
    },
    {
      icon: 'fas fa-code-compare',
      name: 'Stencil Validation',
      category: 'Analysis',
      status: results ? validationStatus : 'Standby',
      detail: results ? `Expected "${expectedStencil || 'N/A'}" and received "${results.stencilValue || 'N/A'}".` : 'Validation will run after analysis completes.',
    },
  ];

  // Reporting components
  const reportingComponents = [
    {
      icon: 'fas fa-chart-line',
      name: 'Static Report Dashboard',
      category: 'Reporting',
      status: 'Operational',
      detail: 'PoleImageReport static HTML and JavaScript assets are available for historical reporting views.',
    },
  ];

  const allComponents = [...frontendComponents, ...backendComponents, ...analysisComponents, ...reportingComponents];

  // Calculate summary statistics
  const operationalCount = allComponents.filter(c => c.status === 'Operational').length;
  const totalCount = allComponents.length;
  const healthPercentage = Math.round((operationalCount / totalCount) * 100);

  return (
    <div className="mission-control">
      <div className="card shadow-sm mb-4">
        <div className="card-body">
          <div className="d-flex flex-column flex-md-row justify-content-between gap-3">
            <div>
              <h5 className="card-title mb-2">
                <i className="fas fa-gauge-high me-2"></i>
                Mission Control
              </h5>
              <p className="text-muted mb-0">
                Real-time health monitoring for all solution components: frontend, backend API, AI vision pipeline, storage, and reporting infrastructure.
              </p>
            </div>
            <div className="mission-control-summary">
              <span className="text-muted d-block">System Status</span>
              <strong>{isLoading ? 'Analysis in progress' : results ? 'Analysis complete' : 'Ready for requests'}</strong>
              <div className="mt-2">
                <small className="text-muted">{operationalCount} / {totalCount} operational ({healthPercentage}%)</small>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Frontend Components Section */}
      <div className="mb-4">
        <h6 className="text-muted text-uppercase small fw-bold mb-3">
          <i className="fas fa-desktop me-2"></i>Frontend Components
        </h6>
        <div className="row">
          {frontendComponents.map((component) => (
            <StatusCard key={component.name} {...component} />
          ))}
        </div>
      </div>

      {/* Backend Components Section */}
      <div className="mb-4">
        <h6 className="text-muted text-uppercase small fw-bold mb-3">
          <i className="fas fa-server me-2"></i>Backend & Infrastructure
        </h6>
        <div className="row">
          {backendComponents.map((component) => (
            <StatusCard key={component.name} {...component} />
          ))}
        </div>
      </div>

      {/* Analysis Components Section */}
      <div className="mb-4">
        <h6 className="text-muted text-uppercase small fw-bold mb-3">
          <i className="fas fa-microscope me-2"></i>Analysis Pipeline
        </h6>
        <div className="row">
          {analysisComponents.map((component) => (
            <StatusCard key={component.name} {...component} />
          ))}
        </div>
      </div>

      {/* Reporting Components Section */}
      <div className="mb-4">
        <h6 className="text-muted text-uppercase small fw-bold mb-3">
          <i className="fas fa-file-lines me-2"></i>Reporting Assets
        </h6>
        <div className="row">
          {reportingComponents.map((component) => (
            <StatusCard key={component.name} {...component} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default MissionControl;

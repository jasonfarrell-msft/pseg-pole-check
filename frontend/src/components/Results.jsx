import React from 'react';

const Results = ({ results, expectedStencil }) => {
  if (!results) {
    return null;
  }

  const { vendorTags, stencilValue, stencilConfidence, isValid } = results;

  return (
    <div className="card shadow-sm">
      <div className="card-body">
        <h5 className="card-title mb-4">Analysis Results</h5>

        {/* Vendor Tags Section */}
        <div className="mb-4">
          <h6 className="fw-bold mb-3">Vendor Tags</h6>
          {vendorTags && vendorTags.length > 0 ? (
            <div className="list-group">
              {vendorTags.map((tag, index) => (
                <div
                  key={index}
                  className="list-group-item d-flex justify-content-between align-items-center"
                >
                  <span>Vendor Tag {index + 1}</span>
                  <span className="badge bg-secondary rounded-pill">
                    {(tag.confidence * 100).toFixed(2)}%
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <div className="alert alert-danger" role="alert">
              No Vendor Tags were found
            </div>
          )}
        </div>

        {/* Stencil Section */}
        <div className="mb-4">
          <h6 className="fw-bold mb-3">Stencil Information</h6>
          <div className="mb-2">
            <small className="text-muted">Expected Stencil:</small>
            <div className="fw-semibold">{expectedStencil || 'N/A'}</div>
          </div>
          <div className="mb-2">
            <small className="text-muted">Extracted Value:</small>
            <div className="fw-semibold">{stencilValue || 'N/A'}</div>
          </div>
          {stencilConfidence !== undefined && (
            <div>
              <small className="text-muted">Confidence:</small>
              <div className="fw-semibold">{(stencilConfidence * 100).toFixed(2)}%</div>
            </div>
          )}
        </div>

        {/* Validation Status */}
        <div className="validation-status text-center mt-5 pt-4">
          {isValid ? (
            <i className="fas fa-check-circle text-success validation-icon"></i>
          ) : (
            <i className="fas fa-times-circle text-danger validation-icon"></i>
          )}
        </div>
      </div>
    </div>
  );
};

export default Results;

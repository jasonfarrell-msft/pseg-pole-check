import React, { useState } from 'react';

const ImageUpload = ({ onUpload, isLoading }) => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [fileName, setFileName] = useState('');

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedFile(file);
      setFileName(file.name);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (selectedFile) {
      onUpload(selectedFile);
    }
  };

  return (
    <div className="card shadow-sm">
      <div className="card-body">
        <h5 className="card-title mb-4">Upload Pole Image</h5>
        <form onSubmit={handleSubmit}>
          <div className="mb-3">
            <label htmlFor="fileInput" className="form-label">
              Select Image File
            </label>
            <input
              type="file"
              className="form-control"
              id="fileInput"
              accept="image/*"
              onChange={handleFileChange}
              disabled={isLoading}
            />
            {fileName && (
              <div className="form-text">
                Selected: {fileName}
              </div>
            )}
          </div>
          <button
            type="submit"
            className="btn btn-primary w-100"
            disabled={!selectedFile || isLoading}
          >
            {isLoading ? (
              <>
                <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                Analyzing...
              </>
            ) : (
              'Analyze Image'
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default ImageUpload;

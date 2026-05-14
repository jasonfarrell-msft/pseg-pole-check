import React, { useState } from 'react';
import ImageUpload from './components/ImageUpload';
import MissionControl from './components/MissionControl';
import Results from './components/Results';
import { analyzeImage } from './services/imageService';
import './App.css';

function App() {
  const [activeTab, setActiveTab] = useState('validator');
  const [isLoading, setIsLoading] = useState(false);
  const [results, setResults] = useState(null);
  const [expectedStencil, setExpectedStencil] = useState('');
  const [error, setError] = useState(null);

  const handleImageUpload = async (file) => {
    setIsLoading(true);
    setError(null);
    // Hide previous results and image when starting new request
    setResults(null);
    setExpectedStencil('');
    
    // Extract expected stencil from filename (first part before _)
    const fileNameParts = file.name.split('_');
    const stencil = fileNameParts[0];
    setExpectedStencil(stencil);

    try {
      const data = await analyzeImage(file);
      setResults(data);
    } catch (err) {
      setError('Failed to analyze image. Please try again.');
      console.error('Upload error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="app">
      {/* Header */}
      <header className="pseg-header">
        <div className="container">
          <h1 className="header-title">
            <i className="fas fa-bolt me-2"></i>
            PSEG Pole Image Validator
          </h1>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mt-4">
        <ul className="nav nav-tabs app-tabs mb-4" role="tablist">
          <li className="nav-item" role="presentation">
            <button
              className={`nav-link ${activeTab === 'validator' ? 'active' : ''}`}
              type="button"
              role="tab"
              aria-selected={activeTab === 'validator'}
              onClick={() => setActiveTab('validator')}
            >
              <i className="fas fa-camera me-2"></i>
              Validator
            </button>
          </li>
          <li className="nav-item" role="presentation">
            <button
              className={`nav-link ${activeTab === 'mission-control' ? 'active' : ''}`}
              type="button"
              role="tab"
              aria-selected={activeTab === 'mission-control'}
              onClick={() => setActiveTab('mission-control')}
            >
              <i className="fas fa-gauge-high me-2"></i>
              Mission Control
            </button>
          </li>
        </ul>

        {activeTab === 'validator' ? (
          <div className="row">
            <div className="col-lg-6 mb-4">
              <ImageUpload onUpload={handleImageUpload} isLoading={isLoading} />
              {error && (
                <div className="alert alert-danger mt-3" role="alert">
                  <i className="fas fa-exclamation-triangle me-2"></i>
                  {error}
                </div>
              )}
              {results && (
                <div className="mt-4">
                  <Results results={results} expectedStencil={expectedStencil} />
                </div>
              )}
            </div>

            <div className="col-lg-6 mb-4">
              {results && results.imageUrl && (
                <div className="card shadow-sm">
                  <div className="card-body">
                    <h5 className="card-title mb-4">Uploaded Image</h5>
                    <div className="uploaded-image-container">
                      <img
                        src={results.imageUrl}
                        alt="Uploaded pole"
                        className="img-fluid rounded"
                      />
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        ) : (
          <MissionControl
            isLoading={isLoading}
            results={results}
            expectedStencil={expectedStencil}
            error={error}
          />
        )}
      </main>
    </div>
  );
}

export default App;

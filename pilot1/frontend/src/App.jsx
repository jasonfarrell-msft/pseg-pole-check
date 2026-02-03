import React, { useState } from 'react';
import ImageUpload from './components/ImageUpload';
import Results from './components/Results';
import { analyzeImage } from './services/imageService';
import './App.css';

function App() {
  const [isLoading, setIsLoading] = useState(false);
  const [results, setResults] = useState(null);
  const [expectedStencil, setExpectedStencil] = useState('');
  const [error, setError] = useState(null);

  const handleImageUpload = async (file) => {
    setIsLoading(true);
    setError(null);
    
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
        <div className="row">
          {/* Upload Form Column - Left Side */}
          <div className="col-lg-6 mb-4">
            <ImageUpload onUpload={handleImageUpload} isLoading={isLoading} />
            {error && (
              <div className="alert alert-danger mt-3" role="alert">
                <i className="fas fa-exclamation-triangle me-2"></i>
                {error}
              </div>
            )}
          </div>

          {/* Results Column - Right Side */}
          <div className="col-lg-6 mb-4">
            <Results results={results} expectedStencil={expectedStencil} />
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;

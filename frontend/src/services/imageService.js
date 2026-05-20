import axios from 'axios';

export const API_BASE_URL = import.meta.env.VITE_API_ENDPOINT || 'http://localhost:8080';
export const API_ENDPOINT = `${API_BASE_URL}/image/analyze`;

/**
 * Upload an image file for analysis
 * @param {File} file - The image file to upload
 * @returns {Promise<Object>} - Analysis results
 */
export const analyzeImage = async (file) => {
  const formData = new FormData();
  formData.append('file', file);

  try {
    const response = await axios.post(API_ENDPOINT, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  } catch (error) {
    console.error('Error analyzing image:', error);
    throw error;
  }
};

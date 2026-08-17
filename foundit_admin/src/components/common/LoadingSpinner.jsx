import React from 'react';

export default function LoadingSpinner({ text = 'Loading...' }) {
  return (
    <div className="loading-overlay">
      <div className="spinner-ring"></div>
      {text && <p className="loading-text">{text}</p>}
    </div>
  );
}

import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

export default function ProtectedRoute({ children }) {
  const { user, userRole, loading } = useAuth();

  if (loading) {
    return (
      <div className="loading-fullscreen">
        <div className="spinner-ring"></div>
        <p>Loading FoundIt Admin...</p>
      </div>
    );
  }

  if (!user) return <Navigate to="/login" replace />;
  if (userRole !== 'admin') {
    return (
      <div className="access-denied">
        <div className="denied-card">
          <span className="denied-icon">🚫</span>
          <h2>Access Denied</h2>
          <p>You do not have admin privileges to access this dashboard.</p>
          <button onClick={() => window.location.href = '/login'} className="btn-primary">
            Back to Login
          </button>
        </div>
      </div>
    );
  }

  return children;
}

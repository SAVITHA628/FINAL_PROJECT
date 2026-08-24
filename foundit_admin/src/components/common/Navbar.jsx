import React from 'react';
import { useAuth } from '../../context/AuthContext';

export default function Navbar({ pageTitle }) {
  const { user, userRole, logout } = useAuth();
  const now = new Date();
  const dateString = now.toLocaleDateString('en-IN', {
    weekday: 'short', year: 'numeric', month: 'short', day: 'numeric'
  });

  const userName = user?.name || user?.email?.split('@')[0] || 'Admin';

  return (
    <header className="navbar">
      <div className="navbar-left">
        <h1 className="page-title">{pageTitle || 'Dashboard'}</h1>
        <span className="page-date">{dateString}</span>
      </div>
      <div className="navbar-right" style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <div className="navbar-badge">
          <span className="badge-dot"></span>
          <span className="badge-text">Firebase Live</span>
        </div>
        <div className="user-profile-badge" style={{ display: 'flex', alignItems: 'center', gap: '10px', background: 'var(--bg-elevated)', padding: '6px 14px', borderRadius: '20px', border: '1px solid var(--border)' }}>
          <div className="user-avatar-sm" style={{ width: 28, height: 28, fontSize: 12 }}>
            {userName[0]?.toUpperCase()}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>{userName}</span>
            <span style={{ fontSize: 10, color: 'var(--primary)', fontWeight: 800, textTransform: 'uppercase' }}>
              🛡️ {userRole || 'ADMIN'}
            </span>
          </div>
        </div>
        <button
          onClick={logout}
          className="btn-secondary"
          style={{ padding: '6px 12px', fontSize: '12px' }}
          title="Sign Out"
        >
          🚪 Logout
        </button>
      </div>
    </header>
  );
}

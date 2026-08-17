import React from 'react';

export default function Navbar({ pageTitle, collapsed }) {
  const now = new Date();
  const dateString = now.toLocaleDateString('en-IN', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
  });

  return (
    <header className="navbar">
      <div className="navbar-left">
        <h1 className="page-title">{pageTitle}</h1>
        <span className="page-date">{dateString}</span>
      </div>
      <div className="navbar-right">
        <div className="navbar-badge">
          <span className="badge-dot"></span>
          <span className="badge-text">Live</span>
        </div>
      </div>
    </header>
  );
}

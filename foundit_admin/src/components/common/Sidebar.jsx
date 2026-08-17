import React from 'react';
import { NavLink } from 'react-router-dom';

export default function Sidebar({ collapsed, onToggle }) {
  const navItems = [
    { path: '/dashboard', label: 'Dashboard', icon: '📊' },
    { path: '/items', label: 'All Items', icon: '📦' },
    { path: '/pending-verification', label: 'Pending Verification', icon: '⏳' },
    { path: '/claims', label: 'Claimed Items', icon: '🟡' },
    { path: '/returned', label: 'Returned Items', icon: '🔵' },
    { path: '/users', label: 'Users', icon: '👥' },
    { path: '/reports', label: 'TAT Report', icon: '📈' },
  ];

  return (
    <aside className={`sidebar ${collapsed ? 'collapsed' : ''}`}>
      <div className="sidebar-header">
        <div className="sidebar-logo">🔍</div>
        {!collapsed && <span className="sidebar-title">FoundIt Admin</span>}
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            title={collapsed ? item.label : undefined}
          >
            <span className="nav-icon">{item.icon}</span>
            {!collapsed && <span className="nav-label">{item.label}</span>}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}

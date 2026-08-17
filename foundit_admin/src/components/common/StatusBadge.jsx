import React from 'react';

const STATUS_CONFIG = {
  active:   { label: 'Active',   color: '#22c55e', bg: 'rgba(34,197,94,0.12)',   icon: '🟢' },
  claimed:  { label: 'Claimed',  color: '#f59e0b', bg: 'rgba(245,158,11,0.12)',  icon: '🟡' },
  returned: { label: 'Returned', color: '#3b82f6', bg: 'rgba(59,130,246,0.12)', icon: '🔵' },
  expired:  { label: 'Expired',  color: '#6b7280', bg: 'rgba(107,114,128,0.12)', icon: '⚫' },
  disputed: { label: 'Disputed', color: '#ef4444', bg: 'rgba(239,68,68,0.12)',   icon: '🔴' },
};

export default function StatusBadge({ status }) {
  const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.active;
  return (
    <span
      className="status-badge"
      style={{ color: cfg.color, background: cfg.bg, border: `1px solid ${cfg.color}40` }}
    >
      {cfg.icon} {cfg.label}
    </span>
  );
}

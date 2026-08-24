import React, { useEffect, useState } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';
import { itemService } from '../services/itemService';
import { dateUtils } from '../utils/dateUtils';
import StatusBadge from '../components/common/StatusBadge';
import LoadingSpinner from '../components/common/LoadingSpinner';

const PIE_COLORS = ['#ef4444', '#22c55e'];
const BAR_COLORS = ['#22c55e', '#f59e0b', '#3b82f6', '#6b7280', '#ef4444'];

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [recentItems, setRecentItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [s, items] = await Promise.all([
          itemService.getStats(),
          itemService.getAllItems(),
        ]);
        setStats(s);
        setRecentItems(items.slice(0, 8));
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) return <LoadingSpinner text="Loading dashboard..." />;
  if (!stats) return (
    <div className="page-container">
      <div style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-secondary)' }}>
        <div style={{ fontSize: 48, marginBottom: 16 }}>⚠️</div>
        <h3 style={{ color: 'var(--text-primary)', marginBottom: 8 }}>Unable to load dashboard data</h3>
        <p>Could not connect to Firebase. Check your internet connection.</p>
        <button className="btn-primary" style={{ marginTop: 20 }} onClick={() => window.location.reload()}>
          🔄 Retry
        </button>
      </div>
    </div>
  );

  const statCards = [
    { label: 'Total Items',  value: stats.total,   icon: '📦', color: '#6366f1', bg: 'rgba(99,102,241,0.1)' },
    { label: 'Lost',         value: stats.lost,    icon: '❌', color: '#ef4444', bg: 'rgba(239,68,68,0.1)'  },
    { label: 'Found',        value: stats.found,   icon: '✅', color: '#22c55e', bg: 'rgba(34,197,94,0.1)'  },
    { label: 'Active',       value: stats.active,  icon: '🟢', color: '#22c55e', bg: 'rgba(34,197,94,0.1)'  },
    { label: 'Claimed',      value: stats.claimed, icon: '🟡', color: '#f59e0b', bg: 'rgba(245,158,11,0.1)' },
    { label: 'Returned',     value: stats.returned,icon: '🔵', color: '#3b82f6', bg: 'rgba(59,130,246,0.1)' },
  ];

  const barData = [
    { name: 'Active',   count: stats.active },
    { name: 'Claimed',  count: stats.claimed },
    { name: 'Returned', count: stats.returned },
    { name: 'Expired',  count: stats.expired },
  ];

  const pieData = [
    { name: 'Lost',  value: stats.lost },
    { name: 'Found', value: stats.found },
  ];

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2>Dashboard Overview</h2>
          <p className="page-subtitle">Real-time snapshot of all FoundIt activity</p>
        </div>
      </div>

      <div className="stats-grid">
        {statCards.map((s) => (
          <div
            key={s.label}
            className="stat-card"
            style={{ '--stat-color': s.color, '--stat-bg': s.bg }}
          >
            <div className="stat-card-header">
              <span className="stat-label">{s.label}</span>
              <span className="stat-icon">{s.icon}</span>
            </div>
            <div className="stat-value">{s.value}</div>
            <div className="stat-sub">items in system</div>
          </div>
        ))}
      </div>

      <div className="charts-grid">
        <div className="chart-card">
          <h3>📊 Items by Status</h3>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={barData} margin={{ top: 4, right: 4, bottom: 4, left: -20 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="name" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ background: '#1a2234', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 8, color: '#f1f5f9' }}
                cursor={{ fill: 'rgba(255,255,255,0.03)' }}
              />
              <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                {barData.map((_, i) => <Cell key={i} fill={BAR_COLORS[i % BAR_COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="chart-card">
          <h3>🍩 Lost vs Found</h3>
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie data={pieData} cx="50%" cy="50%" innerRadius={60} outerRadius={90} paddingAngle={4} dataKey="value">
                {pieData.map((_, i) => <Cell key={i} fill={PIE_COLORS[i]} />)}
              </Pie>
              <Legend
                formatter={(v) => <span style={{ color: '#94a3b8', fontSize: 13 }}>{v}</span>}
              />
              <Tooltip
                contentStyle={{ background: '#1a2234', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 8, color: '#f1f5f9' }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="recent-section">
        <h3>🕒 Recent Items</h3>
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Item</th>
                <th>Type</th>
                <th>Status</th>
                <th>Reporter</th>
                <th>Location</th>
                <th>Reported</th>
              </tr>
            </thead>
            <tbody>
              {recentItems.length === 0 ? (
                <tr><td colSpan={6} className="table-empty"><div className="table-empty-icon">📭</div>No items yet</td></tr>
              ) : recentItems.map((item) => (
                <tr key={item.id}>
                  <td><strong>{item.title}</strong></td>
                  <td>
                    <span className={`type-badge type-${item.type}`}>
                      {item.type === 'lost' ? '❌' : '✅'} {item.type}
                    </span>
                  </td>
                  <td><StatusBadge status={item.status} /></td>
                  <td>{item.reporterName || '—'}</td>
                  <td>{item.location || '—'}</td>
                  <td>{dateUtils.formatDate(item.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

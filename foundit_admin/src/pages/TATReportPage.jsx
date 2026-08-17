import React, { useEffect, useState } from 'react';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts';
import { itemService } from '../services/itemService';
import { dateUtils, exportToCSV } from '../utils/dateUtils';
import LoadingSpinner from '../components/common/LoadingSpinner';

function groupByMonth(items) {
  const map = {};
  items.forEach((item) => {
    if (!item.createdAt) return;
    const d = item.createdAt?.toDate ? item.createdAt.toDate() : new Date(item.createdAt);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    if (!map[key]) map[key] = { month: key, reported: 0, claimed: 0, returned: 0 };
    map[key].reported++;
    if (['claimed', 'returned'].includes(item.status)) map[key].claimed++;
    if (item.status === 'returned') map[key].returned++;
  });
  return Object.values(map).sort((a, b) => a.month.localeCompare(b.month)).slice(-6);
}

export default function TATReportPage() {
  const [allItems, setAllItems] = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [loading, setLoading] = useState(true);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [chartData, setChartData] = useState([]);

  useEffect(() => {
    itemService.getAllItems().then((data) => {
      setAllItems(data);
      setFiltered(data);
      setChartData(groupByMonth(data));
      setLoading(false);
    });
  }, []);

  const handleFilter = () => {
    const result = allItems.filter((i) => dateUtils.isInRange(i.createdAt, startDate, endDate));
    setFiltered(result);
    setChartData(groupByMonth(result));
  };

  const handleReset = () => {
    setStartDate('');
    setEndDate('');
    setFiltered(allItems);
    setChartData(groupByMonth(allItems));
  };

  const returnedItems = filtered.filter((i) => i.status === 'returned' && i.createdAt && i.returnedAt);
  const avgTAT = returnedItems.length
    ? Math.round(
        returnedItems.reduce((acc, i) => acc + (dateUtils.diffDays(i.createdAt, i.returnedAt) || 0), 0)
        / returnedItems.length
      )
    : 0;

  const handleExport = () => {
    const rows = filtered.map((i) => ({
      ID: i.id,
      Title: i.title,
      Type: i.type,
      Status: i.status,
      Category: i.category || '',
      Reporter: i.reporterName || '',
      Location: i.location || '',
      Reported: dateUtils.formatDate(i.createdAt),
      'Claimed At': dateUtils.formatDate(i.claimedAt),
      'Returned At': dateUtils.formatDate(i.returnedAt),
      'TAT (days)': i.returnedAt && i.createdAt ? dateUtils.diffDays(i.createdAt, i.returnedAt) : '',
      Verified: i.verifiedByAdmin ? 'Yes' : 'No',
    }));
    exportToCSV(rows, `foundit-tat-report-${new Date().toISOString().slice(0, 10)}.csv`);
  };

  if (loading) return <LoadingSpinner text="Generating report..." />;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2>TAT Report</h2>
          <p className="page-subtitle">Turnaround time analysis for all reported items</p>
        </div>
        <button className="btn-primary" onClick={handleExport}>
          ⬇️ Export CSV
        </button>
      </div>

      <div className="card" style={{ marginBottom: 24 }}>
        <div style={{ display: 'flex', gap: 16, alignItems: 'flex-end', flexWrap: 'wrap' }}>
          <div className="input-group" style={{ marginBottom: 0, flex: 1, minWidth: 180 }}>
            <label>From Date</label>
            <input type="date" id="tat-start" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          </div>
          <div className="input-group" style={{ marginBottom: 0, flex: 1, minWidth: 180 }}>
            <label>To Date</label>
            <input type="date" id="tat-end" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          </div>
          <button className="btn-primary" onClick={handleFilter}>🔍 Apply Filter</button>
          <button className="btn-ghost" onClick={handleReset}>↺ Reset</button>
        </div>
      </div>

      <div className="tat-stat-row">
        <div className="tat-stat">
          <div className="tat-value">{filtered.length}</div>
          <div className="tat-label">Total Items in Range</div>
        </div>
        <div className="tat-stat">
          <div className="tat-value">{returnedItems.length}</div>
          <div className="tat-label">Successfully Returned</div>
        </div>
        <div className="tat-stat">
          <div className="tat-value">{avgTAT}<span style={{ fontSize: 14, fontWeight: 400, color: 'var(--text-muted)', marginLeft: 4 }}>days</span></div>
          <div className="tat-label">Avg. Turnaround Time</div>
        </div>
      </div>

      <div className="chart-card" style={{ marginBottom: 24 }}>
        <h3>📈 Monthly Trend (Last 6 Months)</h3>
        <ResponsiveContainer width="100%" height={260}>
          <LineChart data={chartData} margin={{ top: 4, right: 16, bottom: 4, left: -20 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
            <XAxis dataKey="month" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
            <Tooltip
              contentStyle={{ background: '#1a2234', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 8, color: '#f1f5f9' }}
            />
            <Legend formatter={(v) => <span style={{ color: '#94a3b8', fontSize: 13 }}>{v}</span>} />
            <Line type="monotone" dataKey="reported" stroke="#6366f1" strokeWidth={2} dot={{ r: 4 }} name="Reported" />
            <Line type="monotone" dataKey="claimed"  stroke="#f59e0b" strokeWidth={2} dot={{ r: 4 }} name="Claimed" />
            <Line type="monotone" dataKey="returned" stroke="#22c55e" strokeWidth={2} dot={{ r: 4 }} name="Returned" />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Title</th>
              <th>Type</th>
              <th>Status</th>
              <th>Reporter</th>
              <th>Reported On</th>
              <th>Claimed At</th>
              <th>Returned At</th>
              <th>TAT (days)</th>
              <th>Verified</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr><td colSpan={9}><div className="table-empty"><div className="table-empty-icon">📊</div><p>No data in selected range</p></div></td></tr>
            ) : filtered.map((item) => (
              <tr key={item.id}>
                <td><strong>{item.title}</strong></td>
                <td><span className={`type-badge type-${item.type}`}>{item.type === 'lost' ? '❌ Lost' : '✅ Found'}</span></td>
                <td>{item.status}</td>
                <td>{item.reporterName || '—'}</td>
                <td>{dateUtils.formatDate(item.createdAt)}</td>
                <td>{dateUtils.formatDate(item.claimedAt)}</td>
                <td>{dateUtils.formatDate(item.returnedAt)}</td>
                <td>
                  {item.returnedAt && item.createdAt
                    ? <strong style={{ color: 'var(--brand-primary)' }}>{dateUtils.diffDays(item.createdAt, item.returnedAt)}d</strong>
                    : '—'
                  }
                </td>
                <td>
                  <span className={`verified-badge ${item.verifiedByAdmin ? 'verified-yes' : 'verified-no'}`}>
                    {item.verifiedByAdmin ? '✅' : '⬜'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

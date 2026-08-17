import React, { useEffect, useState } from 'react';
import { itemService } from '../services/itemService';
import { dateUtils } from '../utils/dateUtils';
import StatusBadge from '../components/common/StatusBadge';
import LoadingSpinner from '../components/common/LoadingSpinner';

const PAGE_SIZE = 10;

export default function ClaimsPage() {
  const [items, setItems] = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(1);

  useEffect(() => {
    itemService.getClaimedItems().then((data) => {
      setItems(data);
      setLoading(false);
    });
  }, []);

  useEffect(() => {
    let result = [...items];
    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter((i) =>
        i.title?.toLowerCase().includes(q) ||
        i.reporterName?.toLowerCase().includes(q)
      );
    }
    if (statusFilter !== 'all') result = result.filter((i) => i.status === statusFilter);
    setFiltered(result);
    setPage(1);
  }, [items, search, statusFilter]);

  const totalPages = Math.ceil(filtered.length / PAGE_SIZE);
  const paginated = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  if (loading) return <LoadingSpinner text="Loading claims..." />;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2>Claims &amp; Returns</h2>
          <p className="page-subtitle">Track claimed and returned items</p>
        </div>
        <div style={{ display: 'flex', gap: 16 }}>
          <div className="stat-card" style={{ padding: '12px 20px', '--stat-color': '#f59e0b' }}>
            <div className="stat-label">Claimed</div>
            <div className="stat-value" style={{ fontSize: 22 }}>{items.filter(i => i.status === 'claimed').length}</div>
          </div>
          <div className="stat-card" style={{ padding: '12px 20px', '--stat-color': '#3b82f6' }}>
            <div className="stat-label">Returned</div>
            <div className="stat-value" style={{ fontSize: 22 }}>{items.filter(i => i.status === 'returned').length}</div>
          </div>
        </div>
      </div>

      <div className="toolbar">
        <div className="search-bar" style={{ flex: 1, maxWidth: 360 }}>
          <span className="search-icon">🔍</span>
          <input
            id="claims-search"
            placeholder="Search by item or reporter..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="filter-tabs">
          {['all', 'claimed', 'returned'].map((s) => (
            <button
              key={s}
              className={`filter-tab ${statusFilter === s ? 'active' : ''}`}
              onClick={() => setStatusFilter(s)}
            >
              {s === 'all' ? 'All' : s === 'claimed' ? '🟡 Claimed' : '🔵 Returned'}
            </button>
          ))}
        </div>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Image</th>
              <th>Item Title</th>
              <th>Type</th>
              <th>Status</th>
              <th>Reporter</th>
              <th>Reporter Phone</th>
              <th>Reported On</th>
              <th>Claimed At</th>
              <th>Returned At</th>
              <th>Ownership Verified</th>
            </tr>
          </thead>
          <tbody>
            {paginated.length === 0 ? (
              <tr><td colSpan={10}><div className="table-empty"><div className="table-empty-icon">🤝</div><p>No claims or returns yet</p></div></td></tr>
            ) : paginated.map((item) => (
              <tr key={item.id}>
                <td>
                  {item.imageUrl
                    ? <img src={item.imageUrl} alt={item.title} className="item-thumb" />
                    : <div className="item-thumb-placeholder">📦</div>
                  }
                </td>
                <td><strong>{item.title}</strong></td>
                <td><span className={`type-badge type-${item.type}`}>{item.type === 'lost' ? '❌ Lost' : '✅ Found'}</span></td>
                <td><StatusBadge status={item.status} /></td>
                <td>{item.reporterName || '—'}</td>
                <td>
                  <a href={`tel:${item.reporterPhone}`} style={{ color: 'var(--brand-primary)' }}>
                    {item.reporterPhone || '—'}
                  </a>
                </td>
                <td>{dateUtils.formatDate(item.createdAt)}</td>
                <td>{dateUtils.formatDate(item.claimedAt)}</td>
                <td>{dateUtils.formatDate(item.returnedAt)}</td>
                <td>
                  <span className={`verified-badge ${item.verifiedByAdmin ? 'verified-yes' : 'verified-no'}`}>
                    {item.verifiedByAdmin ? '✅ Yes' : '⬜ No'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {totalPages > 1 && (
          <div className="pagination">
            <span>Showing {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, filtered.length)} of {filtered.length}</span>
            <div className="pagination-controls">
              <button className="page-btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>‹</button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                <button key={p} className={`page-btn ${p === page ? 'active' : ''}`} onClick={() => setPage(p)}>{p}</button>
              ))}
              <button className="page-btn" disabled={page === totalPages} onClick={() => setPage(p => p + 1)}>›</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

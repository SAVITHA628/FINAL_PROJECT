import React, { useEffect, useState, useCallback } from 'react';
import { itemService } from '../services/itemService';
import { dateUtils } from '../utils/dateUtils';
import StatusBadge from '../components/common/StatusBadge';
import ConfirmDialog from '../components/common/ConfirmDialog';
import LoadingSpinner from '../components/common/LoadingSpinner';

const STATUSES = ['all', 'active', 'claimed', 'returned', 'expired', 'disputed'];
const TYPES = ['all', 'lost', 'found'];
const PAGE_SIZE = 10;

function ItemDetailModal({ item, onClose, onStatusUpdate }) {
  const [newStatus, setNewStatus] = useState(item.status);
  const [adminNotes, setAdminNotes] = useState(item.adminNotes || '');
  const [verified, setVerified] = useState(item.verifiedByAdmin || false);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      if (newStatus !== item.status || adminNotes !== item.adminNotes) {
        await itemService.updateItemStatus(item.id, newStatus, adminNotes);
      }
      if (verified !== item.verifiedByAdmin) {
        await itemService.verifyOwnership(item.id, verified);
      }
      onStatusUpdate();
      onClose();
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" style={{ maxWidth: 720 }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">📦 Item Details</span>
          <button className="modal-close" onClick={onClose}>×</button>
        </div>

        {item.imageUrl && (
          <img src={item.imageUrl} alt={item.title} className="item-image-preview" />
        )}

        <div className="item-detail-grid">
          <div>
            <div className="detail-field">
              <div className="detail-label">Title</div>
              <div className="detail-value" style={{ fontSize: 16, fontWeight: 700 }}>{item.title}</div>
            </div>
            <div className="detail-field">
              <div className="detail-label">Type</div>
              <div className="detail-value">
                <span className={`type-badge type-${item.type}`}>{item.type === 'lost' ? '❌ Lost' : '✅ Found'}</span>
              </div>
            </div>
            <div className="detail-field">
              <div className="detail-label">Category</div>
              <div className="detail-value">{item.category || '—'}</div>
            </div>
            <div className="detail-field">
              <div className="detail-label">Location</div>
              <div className="detail-value">📍 {item.location || '—'}</div>
            </div>
            <div className="detail-field">
              <div className="detail-label">Date Lost/Found</div>
              <div className="detail-value">{dateUtils.formatDate(item.dateLostOrFound)}</div>
            </div>
          </div>

          <div>
            <div className="detail-field">
              <div className="detail-label">Reporter</div>
              <div className="detail-value">{item.reporterName || '—'}</div>
            </div>
            <div className="detail-field">
              <div className="detail-label">Phone</div>
              <div className="detail-value">
                <a href={`tel:${item.reporterPhone}`} style={{ color: 'var(--brand-primary)' }}>
                  {item.reporterPhone || '—'}
                </a>
              </div>
            </div>
            <div className="detail-field">
              <div className="detail-label">Reported On</div>
              <div className="detail-value">{dateUtils.formatDateTime(item.createdAt)}</div>
            </div>
            <div className="detail-field">
              <div className="detail-label">Current Status</div>
              <div className="detail-value"><StatusBadge status={item.status} /></div>
            </div>
            {item.claimedAt && (
              <div className="detail-field">
                <div className="detail-label">Claimed At</div>
                <div className="detail-value">{dateUtils.formatDateTime(item.claimedAt)}</div>
              </div>
            )}
            {item.returnedAt && (
              <div className="detail-field">
                <div className="detail-label">Returned At</div>
                <div className="detail-value">{dateUtils.formatDateTime(item.returnedAt)}</div>
              </div>
            )}
          </div>
        </div>

        <div className="detail-field" style={{ marginTop: 4 }}>
          <div className="detail-label">Description</div>
          <div className="detail-value" style={{ color: 'var(--text-secondary)', lineHeight: 1.7 }}>
            {item.description || 'No description provided.'}
          </div>
        </div>

        <div className="divider"></div>

        <h4 style={{ marginBottom: 16, fontSize: 14, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          🛡️ Admin Actions
        </h4>

        <div className="item-detail-grid">
          <div className="input-group">
            <label>Update Status</label>
            <select value={newStatus} onChange={(e) => setNewStatus(e.target.value)}>
              <option value="active">🟢 Active</option>
              <option value="claimed">🟡 Claimed</option>
              <option value="returned">🔵 Returned</option>
              <option value="expired">⚫ Expired</option>
              <option value="disputed">🔴 Disputed</option>
            </select>
          </div>
          <div className="input-group">
            <label>Ownership Verified</label>
            <select value={verified ? 'yes' : 'no'} onChange={(e) => setVerified(e.target.value === 'yes')}>
              <option value="no">❌ Not Verified</option>
              <option value="yes">✅ Verified</option>
            </select>
          </div>
        </div>

        <div className="input-group">
          <label>Admin Notes</label>
          <textarea
            rows={3}
            placeholder="Add internal notes about this item..."
            value={adminNotes}
            onChange={(e) => setAdminNotes(e.target.value)}
            style={{ resize: 'vertical' }}
          />
        </div>

        <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end', marginTop: 8 }}>
          <button className="btn-ghost" onClick={onClose}>Cancel</button>
          <button className="btn-primary" onClick={handleSave} disabled={saving}>
            {saving ? '⏳ Saving...' : '💾 Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function ItemsPage() {
  const [items, setItems] = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [selectedItem, setSelectedItem] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [page, setPage] = useState(1);

  const loadItems = useCallback(async () => {
    const data = await itemService.getAllItems();
    setItems(data);
    setLoading(false);
  }, []);

  useEffect(() => { loadItems(); }, [loadItems]);

  useEffect(() => {
    let result = [...items];
    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter((i) =>
        i.title?.toLowerCase().includes(q) ||
        i.description?.toLowerCase().includes(q) ||
        i.reporterName?.toLowerCase().includes(q) ||
        i.location?.toLowerCase().includes(q) ||
        i.category?.toLowerCase().includes(q)
      );
    }
    if (statusFilter !== 'all') result = result.filter((i) => i.status === statusFilter);
    if (typeFilter !== 'all') result = result.filter((i) => i.type === typeFilter);
    setFiltered(result);
    setPage(1);
  }, [items, search, statusFilter, typeFilter]);

  const handleDelete = async () => {
    await itemService.deleteItem(deleteTarget.id);
    setDeleteTarget(null);
    loadItems();
  };

  const totalPages = Math.ceil(filtered.length / PAGE_SIZE);
  const paginated = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  if (loading) return <LoadingSpinner text="Loading items..." />;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2>Item Management</h2>
          <p className="page-subtitle">{filtered.length} items found</p>
        </div>
      </div>

      <div className="toolbar">
        <div className="search-bar" style={{ flex: 1, maxWidth: 360 }}>
          <span className="search-icon">🔍</span>
          <input
            id="item-search"
            placeholder="Search by title, reporter, location..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="filter-tabs">
          {TYPES.map((t) => (
            <button
              key={t}
              className={`filter-tab ${typeFilter === t ? 'active' : ''}`}
              onClick={() => setTypeFilter(t)}
            >
              {t === 'all' ? 'All Types' : t === 'lost' ? '❌ Lost' : '✅ Found'}
            </button>
          ))}
        </div>

        <select
          id="status-filter"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          style={{ width: 'auto', padding: '9px 14px' }}
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>{s === 'all' ? 'All Statuses' : s.charAt(0).toUpperCase() + s.slice(1)}</option>
          ))}
        </select>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Image</th>
              <th>Title</th>
              <th>Type</th>
              <th>Status</th>
              <th>Category</th>
              <th>Reporter</th>
              <th>Location</th>
              <th>Verified</th>
              <th>Reported</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {paginated.length === 0 ? (
              <tr>
                <td colSpan={10}>
                  <div className="table-empty">
                    <div className="table-empty-icon">📭</div>
                    <p>No items match your filters</p>
                  </div>
                </td>
              </tr>
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
                <td>{item.category || '—'}</td>
                <td>{item.reporterName || '—'}</td>
                <td>{item.location || '—'}</td>
                <td>
                  <span className={`verified-badge ${item.verifiedByAdmin ? 'verified-yes' : 'verified-no'}`}>
                    {item.verifiedByAdmin ? '✅ Yes' : '⬜ No'}
                  </span>
                </td>
                <td>{dateUtils.formatDate(item.createdAt)}</td>
                <td>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn-icon" title="View / Edit" onClick={() => setSelectedItem(item)}>✏️</button>
                    <button className="btn-icon" title="Deactivate" onClick={() => setDeleteTarget(item)} style={{ color: 'var(--red)' }}>🗑️</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {totalPages > 1 && (
          <div className="pagination">
            <span>Showing {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, filtered.length)} of {filtered.length}</span>
            <div className="pagination-controls">
              <button className="page-btn" disabled={page === 1} onClick={() => setPage(1)}>«</button>
              <button className="page-btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>‹</button>
              {Array.from({ length: totalPages }, (_, i) => i + 1)
                .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
                .map((p, idx, arr) => (
                  <React.Fragment key={p}>
                    {idx > 0 && arr[idx - 1] !== p - 1 && <span style={{ color: 'var(--text-muted)', padding: '0 4px' }}>…</span>}
                    <button className={`page-btn ${p === page ? 'active' : ''}`} onClick={() => setPage(p)}>{p}</button>
                  </React.Fragment>
                ))
              }
              <button className="page-btn" disabled={page === totalPages} onClick={() => setPage(p => p + 1)}>›</button>
              <button className="page-btn" disabled={page === totalPages} onClick={() => setPage(totalPages)}>»</button>
            </div>
          </div>
        )}
      </div>

      {selectedItem && (
        <ItemDetailModal
          item={selectedItem}
          onClose={() => setSelectedItem(null)}
          onStatusUpdate={loadItems}
        />
      )}

      <ConfirmDialog
        isOpen={!!deleteTarget}
        title="Deactivate Item"
        message={`Are you sure you want to deactivate "${deleteTarget?.title}"? It will be hidden from the public listing.`}
        confirmLabel="Deactivate"
        confirmVariant="danger"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
}

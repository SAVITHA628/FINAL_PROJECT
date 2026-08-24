import React, { useEffect, useState } from 'react';
import { userService } from '../services/userService';
import { dateUtils } from '../utils/dateUtils';
import ConfirmDialog from '../components/common/ConfirmDialog';
import LoadingSpinner from '../components/common/LoadingSpinner';

const PAGE_SIZE = 10;

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [page, setPage] = useState(1);
  const [actionTarget, setActionTarget] = useState(null);
  const [actionType, setActionType] = useState('');

  const loadUsers = async () => {
    try {
      const data = await userService.getAllUsers();
      setUsers(data);
    } catch (err) {
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadUsers(); }, []);

  useEffect(() => {
    let result = [...users];
    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter((u) =>
        u.name?.toLowerCase().includes(q) ||
        u.email?.toLowerCase().includes(q) ||
        u.phone?.toLowerCase().includes(q)
      );
    }
    if (roleFilter !== 'all') result = result.filter((u) => u.role === roleFilter);
    setFiltered(result);
    setPage(1);
  }, [users, search, roleFilter]);

  const handleConfirm = async () => {
    if (actionType === 'deactivate') await userService.toggleUserActive(actionTarget.id, false);
    if (actionType === 'activate') await userService.toggleUserActive(actionTarget.id, true);
    if (actionType === 'promote') await userService.promoteToAdmin(actionTarget.id);
    if (actionType === 'demote') await userService.demoteToUser(actionTarget.id);
    setActionTarget(null);
    setActionType('');
    loadUsers();
  };

  const confirmMessages = {
    deactivate: { title: 'Deactivate User', message: `Deactivate "${actionTarget?.name}"? They will lose access to the app.`, label: 'Deactivate', variant: 'danger' },
    activate: { title: 'Activate User', message: `Restore access for "${actionTarget?.name}"?`, label: 'Activate', variant: 'primary' },
    promote: { title: 'Promote to Admin', message: `Grant admin access to "${actionTarget?.name}"?`, label: 'Promote', variant: 'primary' },
    demote: { title: 'Remove Admin Role', message: `Remove admin access from "${actionTarget?.name}"?`, label: 'Remove', variant: 'danger' },
  };

  const msg = actionType ? confirmMessages[actionType] : {};
  const totalPages = Math.ceil(filtered.length / PAGE_SIZE);
  const paginated = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  if (loading) return <LoadingSpinner text="Loading users..." />;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2>User Management</h2>
          <p className="page-subtitle">{filtered.length} registered users</p>
        </div>
      </div>

      <div className="toolbar">
        <div className="search-bar" style={{ flex: 1, maxWidth: 360 }}>
          <span className="search-icon">🔍</span>
          <input
            id="user-search"
            placeholder="Search by name, email, or phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="filter-tabs">
          {['all', 'user', 'admin'].map((r) => (
            <button
              key={r}
              className={`filter-tab ${roleFilter === r ? 'active' : ''}`}
              onClick={() => setRoleFilter(r)}
            >
              {r === 'all' ? 'All Roles' : r === 'admin' ? '🛡️ Admins' : '👤 Users'}
            </button>
          ))}
        </div>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Role</th>
              <th>Status</th>
              <th>Joined</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {paginated.length === 0 ? (
              <tr><td colSpan={7}><div className="table-empty"><div className="table-empty-icon">👥</div><p>No users found</p></div></td></tr>
            ) : paginated.map((user) => (
              <tr key={user.id}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div className="user-avatar" style={{ width: 32, height: 32, fontSize: 12 }}>
                      {user.name?.[0]?.toUpperCase() || '?'}
                    </div>
                    <strong>{user.name || '—'}</strong>
                  </div>
                </td>
                <td>{user.email}</td>
                <td>{user.phone || '—'}</td>
                <td>
                  <span className={`role-badge ${user.role === 'admin' ? 'role-admin' : 'role-user'}`}>
                    {user.role === 'admin' ? '🛡️ Admin' : '👤 User'}
                  </span>
                </td>
                <td>
                  <span className={`verified-badge ${user.isActive !== false ? 'verified-yes' : 'verified-no'}`}>
                    {user.isActive !== false ? '✅ Active' : '🚫 Inactive'}
                  </span>
                </td>
                <td>{dateUtils.formatDate(user.createdAt)}</td>
                <td>
                  <div style={{ display: 'flex', gap: 6 }}>
                    {user.isActive !== false ? (
                      <button className="btn-icon btn-sm" title="Deactivate"
                        onClick={() => { setActionTarget(user); setActionType('deactivate'); }}>🚫</button>
                    ) : (
                      <button className="btn-icon btn-sm" title="Activate"
                        onClick={() => { setActionTarget(user); setActionType('activate'); }}>✅</button>
                    )}
                    {user.role !== 'admin' ? (
                      <button className="btn-icon btn-sm" title="Promote to Admin"
                        onClick={() => { setActionTarget(user); setActionType('promote'); }}>🛡️</button>
                    ) : (
                      <button className="btn-icon btn-sm" title="Remove Admin"
                        onClick={() => { setActionTarget(user); setActionType('demote'); }}>👤</button>
                    )}
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
              <button className="page-btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>‹</button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                <button key={p} className={`page-btn ${p === page ? 'active' : ''}`} onClick={() => setPage(p)}>{p}</button>
              ))}
              <button className="page-btn" disabled={page === totalPages} onClick={() => setPage(p => p + 1)}>›</button>
            </div>
          </div>
        )}
      </div>

      <ConfirmDialog
        isOpen={!!actionTarget}
        title={msg.title || ''}
        message={msg.message || ''}
        confirmLabel={msg.label || 'Confirm'}
        confirmVariant={msg.variant || 'primary'}
        onConfirm={handleConfirm}
        onCancel={() => { setActionTarget(null); setActionType(''); }}
      />
    </div>
  );
}

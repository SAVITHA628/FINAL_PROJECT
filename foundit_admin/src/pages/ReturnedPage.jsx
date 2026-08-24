import React, { useEffect, useState } from 'react';
import { itemService } from '../services/itemService';
import { dateUtils } from '../utils/dateUtils';
import LoadingSpinner from '../components/common/LoadingSpinner';

export default function ReturnedPage() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const data = await itemService.getAllItems();
        const returned = data.filter(i => i.status === 'returned');
        setItems(returned);
      } catch (err) {
        setItems([]);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) return <LoadingSpinner text="Loading returned items..." />;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2>🔵 Returned Items Log</h2>
          <p className="page-subtitle">
            Successfully returned items archive ({items.length} items returned to owners)
          </p>
        </div>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th>Category</th>
              <th>Reporter</th>
              <th>Claimed By</th>
              <th>Returned Date</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {items.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '32px' }}>
                  No returned items recorded yet.
                </td>
              </tr>
            ) : (
              items.map((item) => (
                <tr key={item.id}>
                  <td>
                    <strong>{item.title}</strong>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                      📍 {item.location}
                    </div>
                  </td>
                  <td>{item.category}</td>
                  <td>{item.reporterName || '—'}</td>
                  <td>{item.claimedBy || 'Verified Owner'}</td>
                  <td>{dateUtils.formatDate(item.returnedAt || item.updatedAt)}</td>
                  <td>
                    <span className="badge badge-returned">RETURNED</span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

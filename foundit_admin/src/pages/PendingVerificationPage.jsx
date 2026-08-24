import React, { useEffect, useState } from 'react';
import { itemService } from '../services/itemService';
import { dateUtils } from '../utils/dateUtils';
import LoadingSpinner from '../components/common/LoadingSpinner';

export default function PendingVerificationPage() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedImage, setSelectedImage] = useState(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await itemService.getAllItems();
      const pending = data.filter(i => i.verificationStatus === 'PENDING');
      setItems(pending);
    } catch (err) {
      setItems([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleVerify = async (itemId) => {
    await itemService.verifyItem(itemId, 'VERIFIED');
    loadData();
  };

  const handleReject = async (itemId) => {
    await itemService.verifyItem(itemId, 'REJECTED');
    loadData();
  };

  if (loading) return <LoadingSpinner text="Loading pending items..." />;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2>⏳ Pending Verification</h2>
          <p className="page-subtitle">
            Review and verify reporter claims & item authenticity ({items.length} pending)
          </p>
        </div>
      </div>

      {items.length === 0 ? (
        <div className="table-wrapper" style={{ padding: '40px', textAlign: 'center' }}>
          <div style={{ fontSize: '36px', marginBottom: '8px' }}>🎉</div>
          <h3>No Pending Verifications</h3>
          <p style={{ color: 'var(--text-muted)', fontSize: '14px' }}>
            All reported items have been verified by administrators!
          </p>
        </div>
      ) : (
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Photo</th>
                <th>Item Details</th>
                <th>Type</th>
                <th>Reporter Info</th>
                <th>Location</th>
                <th>Reported On</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.id}>
                  <td>
                    {item.imageUrl ? (
                      <img
                        src={item.imageUrl}
                        alt={item.title}
                        style={{
                          width: '48px',
                          height: '48px',
                          borderRadius: '8px',
                          objectFit: 'cover',
                          cursor: 'pointer',
                        }}
                        onClick={() => setSelectedImage(item.imageUrl)}
                      />
                    ) : (
                      <div
                        style={{
                          width: '48px',
                          height: '48px',
                          borderRadius: '8px',
                          backgroundColor: 'var(--bg-elevated)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: '20px',
                        }}
                      >
                        📦
                      </div>
                    )}
                  </td>
                  <td>
                    <strong>{item.title}</strong>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                      {item.category} • {item.description}
                    </div>
                  </td>
                  <td>
                    <span className={`type-badge type-${(item.itemType || item.type || '').toLowerCase()}`}>
                      {(item.itemType || item.type || 'lost').toUpperCase()}
                    </span>
                  </td>
                  <td>
                    <div><strong>{item.reporterName || 'Anonymous'}</strong></div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                      📞 {item.reporterPhone || 'No phone'}
                    </div>
                  </td>
                  <td>{item.location}</td>
                  <td>{dateUtils.formatDate(item.createdAt)}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        className="btn-primary"
                        style={{ padding: '6px 12px', fontSize: '12px', background: 'var(--status-active)' }}
                        onClick={() => handleVerify(item.id)}
                      >
                        ✓ Verify
                      </button>
                      <button
                        className="btn-secondary"
                        style={{ padding: '6px 12px', fontSize: '12px', color: 'var(--status-disputed)' }}
                        onClick={() => handleReject(item.id)}
                      >
                        ✕ Reject
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {selectedImage && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0,0,0,0.8)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
          }}
          onClick={() => setSelectedImage(null)}
        >
          <img
            src={selectedImage}
            alt="Item Large View"
            style={{ maxWidth: '90%', maxHeight: '80%', borderRadius: '16px' }}
          />
        </div>
      )}
    </div>
  );
}

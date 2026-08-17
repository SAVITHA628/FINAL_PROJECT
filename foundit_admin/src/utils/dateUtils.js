export const dateUtils = {
  formatDate(timestamp) {
    if (!timestamp) return '—';
    const date = timestamp?.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric'
    });
  },

  formatDateTime(timestamp) {
    if (!timestamp) return '—';
    const date = timestamp?.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  },

  diffDays(from, to) {
    if (!from || !to) return null;
    const a = from?.toDate ? from.toDate() : new Date(from);
    const b = to?.toDate ? to.toDate() : new Date(to);
    return Math.round(Math.abs(b - a) / (1000 * 60 * 60 * 24));
  },

  isInRange(timestamp, start, end) {
    if (!timestamp) return false;
    const date = timestamp?.toDate ? timestamp.toDate() : new Date(timestamp);
    return (!start || date >= new Date(start)) && (!end || date <= new Date(end + 'T23:59:59'));
  },
};

export function exportToCSV(data, filename = 'export.csv') {
  if (!data.length) return;
  const headers = Object.keys(data[0]);
  const rows = data.map((row) =>
    headers.map((h) => JSON.stringify(row[h] ?? '')).join(',')
  );
  const csv = [headers.join(','), ...rows].join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

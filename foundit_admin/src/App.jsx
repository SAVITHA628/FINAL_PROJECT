import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/common/ProtectedRoute';
import Sidebar from './components/common/Sidebar';
import Navbar from './components/common/Navbar';

import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ItemsPage from './pages/ItemsPage';
import PendingVerificationPage from './pages/PendingVerificationPage';
import ClaimsPage from './pages/ClaimsPage';
import ReturnedPage from './pages/ReturnedPage';
import UsersPage from './pages/UsersPage';
import TATReportPage from './pages/TATReportPage';

export default function App() {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<LoginPage />} />

          <Route
            path="/*"
            element={
              <ProtectedRoute>
                <div className="app-layout">
                  <Sidebar collapsed={collapsed} onToggle={() => setCollapsed(!collapsed)} />
                  <div className="main-content">
                    <Navbar />
                    <Routes>
                      <Route path="/dashboard" element={<DashboardPage />} />
                      <Route path="/items" element={<ItemsPage />} />
                      <Route path="/pending-verification" element={<PendingVerificationPage />} />
                      <Route path="/claims" element={<ClaimsPage />} />
                      <Route path="/returned" element={<ReturnedPage />} />
                      <Route path="/users" element={<UsersPage />} />
                      <Route path="/reports" element={<TATReportPage />} />
                      <Route path="*" element={<Navigate to="/dashboard" replace />} />
                    </Routes>
                  </div>
                </div>
              </ProtectedRoute>
            }
          />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

import React from 'react';
import { useAuth } from '../firebase'; // Assuming useAuth provides current user
import { Navigate, Outlet } from 'react-router-dom';

const AdminRoute: React.FC = () => {
  const { currentUser, loading } = useAuth();

  if (loading) {
    return <div className="text-center p-4">Loading authentication...</div>;
  }

  if (currentUser && currentUser.role === 'admin') {
    return <Outlet />;
  } else {
    // Redirect to home or login page if not authenticated or not an admin
    return <Navigate to="/login" replace />;
  }
};

export default AdminRoute;

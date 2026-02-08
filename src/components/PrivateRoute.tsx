import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';

const PrivateRoute = () => {
  const token = localStorage.getItem('access_token');

  // A more robust check would be to validate the token's expiration
  // For now, we'll just check for its presence.
  return token ? <Outlet /> : <Navigate to="/login" />;
};

export default PrivateRoute;

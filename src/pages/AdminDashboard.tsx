import React, { useEffect, useState } from 'react';
import { useAuth } from '../lib/hooks/useAuth'; // Assuming useAuth provides current user and token
import { useNavigate } from 'react-router-dom';

interface User {
  id: number;
  username: string;
  email: string;
  role: string;
  subscription_status: string;
}

const AdminDashboard: React.FC = () => {
  const { currentUser, userToken } = useAuth();
  const navigate = useNavigate();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingUserId, setEditingUserId] = useState<number | null>(null);
  const [newSubscriptionStatus, setNewSubscriptionStatus] = useState<string>('');
  const [editingUserRole, setEditingUserRole] = useState<number | null>(null);
  const [newRole, setNewRole] = useState<string>('');

  const handleUpdateRole = async (userId: number) => {
    if (!userToken) {
      setError('Authentication token missing. Please log in again.');
      navigate('/login');
      return;
    }

    try {
      const response = await fetch(`http://localhost:8000/admin/users/${userId}/role`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${userToken}`,
        },
        body: JSON.stringify({ role: newRole }),
      });

      if (!response.ok) {
        throw new Error(`Failed to update user role: ${response.statusText}`);
      }

      const updatedUser = await response.json();

      setUsers((prevUsers) =>
        prevUsers.map((user) => (user.id === userId ? updatedUser : user))
      );
      setEditingUserRole(null); // Exit editing mode
      setError(null); // Clear any previous errors
    } catch (err: any) {
      setError(err.message || 'Failed to update user role.');
    }
  };

  const handleUpdateSubscription = async (userId: number) => {
    if (!userToken) {
      setError('Authentication token missing. Please log in again.');
      navigate('/login');
      return;
    }

    try {
      const response = await fetch(`http://localhost:8000/admin/users/${userId}/subscription`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${userToken}`,
        },
        body: JSON.stringify({ subscription_status: newSubscriptionStatus }),
      });

      if (!response.ok) {
        throw new Error(`Failed to update subscription: ${response.statusText}`);
      }

      const updatedUser = await response.json();

      setUsers((prevUsers) =>
        prevUsers.map((user) => (user.id === userId ? updatedUser : user))
      );
      setEditingUserId(null); // Exit editing mode
      setError(null); // Clear any previous errors
    } catch (err: any) {
      setError(err.message || 'Failed to update user subscription.');
    }
  };

  useEffect(() => {
    const fetchUsers = async () => {
      if (!userToken) {
        navigate('/login');
        return;
      }

      if (currentUser?.role !== 'admin') {
        setError('You are not authorized to view this page.');
        setLoading(false);
        return;
      }

      try {
        const response = await fetch('http://localhost:8000/admin/users', {
          headers: {
            'Authorization': `Bearer ${userToken}`,
          },
        });

        if (!response.ok) {
          if (response.status === 403) {
            setError('You do not have administrative privileges.');
          } else {
            throw new Error(`Error fetching users: ${response.statusText}`);
          }
        } else {
          const data: User[] = await response.json();
          setUsers(data);
        }
      } catch (err: any) {
        setError(err.message || 'Failed to fetch users.');
      } finally {
        setLoading(false);
      }
    };

    fetchUsers();
  }, [currentUser, userToken, navigate]);

  if (loading) {
    return <div className="text-center p-4">Loading admin dashboard...</div>;
  }

  if (error) {
    return <div className="text-center p-4 text-red-500">{error}</div>;
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Admin Dashboard</h1>
      <h2 className="text-xl font-semibold mb-3">User Management</h2>
      <div className="overflow-x-auto bg-white shadow-md rounded-lg">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Username</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subscription</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id}>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{user.id}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.username}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.email}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.role}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.subscription_status}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  {/* Edit Role functionality */}
                  {editingUserRole === user.id ? (
                    <div className="flex items-center space-x-2 mb-2">
                      <select
                        value={newRole}
                        onChange={(e) => setNewRole(e.target.value)}
                        className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                      >
                        <option value="user">User</option>
                        <option value="admin">Admin</option>
                      </select>
                      <button
                        onClick={() => handleUpdateRole(user.id)}
                        className="px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                      >
                        Save
                      </button>
                      <button
                        onClick={() => setEditingUserRole(null)}
                        className="px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-gray-700 bg-gray-200 hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                      >
                        Cancel
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => {
                        setEditingUserRole(user.id);
                        setNewRole(user.role);
                      }}
                      className="text-indigo-600 hover:text-indigo-900 mr-2"
                    >
                      Edit Role
                    </button>
                  )}

                  {/* Edit Subscription functionality */}
                  {editingUserId === user.id ? (
                    <div className="flex items-center space-x-2">
                      <select
                        value={newSubscriptionStatus}
                        onChange={(e) => setNewSubscriptionStatus(e.target.value)}
                        className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                      >
                        <option value="basic">Basic</option>
                        <option value="pro">Pro</option>
                        <option value="premium">Premium</option>
                      </select>
                      <button
                        onClick={() => handleUpdateSubscription(user.id)}
                        className="px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                      >
                        Save
                      </button>
                      <button
                        onClick={() => setEditingUserId(null)}
                        className="px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-gray-700 bg-gray-200 hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                      >
                        Cancel
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => {
                        setEditingUserId(user.id);
                        setNewSubscriptionStatus(user.subscription_status);
                      }}
                      className="text-blue-600 hover:text-blue-900"
                    >
                      Edit Subscription
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default AdminDashboard;

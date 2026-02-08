import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

export default function UserProfile() {
  const navigate = useNavigate();
  const [isOpen, setIsOpen] = useState(false);

  const handleLogout = () => {
    localStorage.removeItem('access_token');
    navigate('/login');
  };
  
  // A simple way to check if the user is logged in for UI purposes.
  const isLoggedIn = !!localStorage.getItem('access_token');


  // If not logged in, you might want to show a Login button instead.
  // For now, we assume this component is only rendered for logged-in users.
  if (!isLoggedIn) {
    return (
      <Link to="/login">
        <button className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md shadow-sm hover:bg-indigo-700">
          Login
        </button>
      </Link>
    );
  }

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center space-x-2 p-1 rounded-md hover:bg-primary-light transition-colors duration-200 focus:outline-none"
      >
        <div className="h-8 w-8 rounded-full bg-neutral-300 flex items-center justify-center text-neutral-700 font-medium text-sm">P</div>
        <div className="hidden md:block">
          <div className="font-medium text-white">Profile</div>
          <div className="text-sm text-neutral-300">View Profile</div>
        </div>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-10">
          <Link
            to="/profile"
            className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
            onClick={() => setIsOpen(false)}
          >
            View Profile
          </Link>
          <button
            onClick={handleLogout}
            className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          >
            Logout
          </button>
        </div>
      )}
    </div>
  );
}

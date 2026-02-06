import React, { useState } from 'react';
import { auth } from '../../firebase';
import { useAuthState } from 'react-firebase-hooks/auth';
import { signOut } from 'firebase/auth';
import { useNavigate } from 'react-router-dom';

export default function UserProfile() {
  const [user] = useAuthState(auth);
  const navigate = useNavigate();
  const [isOpen, setIsOpen] = useState(false);

  const displayName = user?.displayName || user?.email || 'Guest';
  const initials = displayName ? displayName.charAt(0).toUpperCase() + displayName.charAt(1).toUpperCase() : 'GU';

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center space-x-2 p-1 rounded-md hover:bg-primary-light transition-colors duration-200 focus:outline-none"
      >
        <div className="h-8 w-8 rounded-full bg-neutral-300 flex items-center justify-center text-neutral-700 font-medium text-sm">{initials}</div>
        <div className="hidden md:block">
          <div className="font-medium text-white">{displayName}</div>
          <div className="text-sm text-neutral-300">View Profile</div>
        </div>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-10">
          <a
            href="/user/:id" // This should ideally link to the actual user profile page
            className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
            onClick={() => setIsOpen(false)}
          >
            View Profile
          </a>
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

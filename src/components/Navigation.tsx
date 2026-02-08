'use client';

import { useState } from 'react';
import Logo from './navigation/Logo';
import DesktopNavLinks from './navigation/DesktopNavLinks';
import NotificationBell from './navigation/NotificationBell';
import UserProfile from './navigation/UserProfile';
import MenuIcon from './navigation/MenuIcon';
import MobileNavLinks from './navigation/MobileNavLinks';
import SearchIcon from '@mui/icons-material/Search';

export default function Navigation() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const toggleDrawer = (open: boolean) => () => {
    setIsMobileMenuOpen(open);
  };

  return (
    <nav className="bg-gradient-to-r from-primary-dark to-primary shadow-lg ring-1 ring-inset ring-black ring-opacity-5">
      <div className="mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          {/* Desktop Left Section: Logo and Nav Links */}
          <div className="flex items-center space-x-4">
            <Logo />
            <DesktopNavLinks />
          </div>

          {/* Desktop Right Section: Notification, User Profile, and Create Listing */}
          <div className="hidden md:flex items-center space-x-4">
            <NotificationBell />
            <UserProfile />
            <a href="/create-listing" className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-accent hover:bg-primary-accent-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-accent">
              Create Listing
            </a>
          </div>

          {/* Mobile Navigation */}
          <div className="flex-grow flex md:hidden justify-between items-center">
            <Logo />
            <button
              type="button"
              className="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
              aria-controls="mobile-menu"
              aria-expanded="false"
              onClick={toggleDrawer(true)}
            >
              <span className="sr-only">Open main menu</span>
              <MenuIcon />
            </button>
            {isMobileMenuOpen && (
              <div className="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 transition-opacity md:hidden" onClick={toggleDrawer(false)}></div>
            )}
            <div className={`fixed inset-y-0 right-0 z-50 w-64 bg-primary-dark text-white shadow-lg transform ${isMobileMenuOpen ? 'translate-x-0 ease-out duration-300' : 'translate-x-full ease-in duration-200'} md:hidden`}>
              <div className="flex items-center justify-between p-4 border-b border-gray-700">
                <Logo />
                <button
                  type="button"
                  className="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                  onClick={toggleDrawer(false)}
                >
                  <span className="sr-only">Close menu</span>
                  {/* Close icon */}
                  <svg className="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
                <div className="block px-3 py-2 rounded-md text-base font-medium text-white hover:bg-gray-700">
                  <UserProfile />
                </div>
                <MobileNavLinks />
                <a href="/create-listing" className="block px-3 py-2 rounded-md text-base font-medium text-white hover:bg-gray-700">Create Listing</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </nav>
  );
}

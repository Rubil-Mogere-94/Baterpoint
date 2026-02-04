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
          {/* Desktop Left Section: Logo, User Profile, and Nav Links */}
          <div className="flex items-center space-x-4">
            <Logo />
            <UserProfile /> {/* UserProfile moved to far left */}
            <DesktopNavLinks />
          </div>

          {/* Search Bar for Desktop (Central) */}
          <div
            className="flex-grow hidden md:flex justify-center items-center max-w-lg mx-4"
          >
            <div className="relative flex items-center w-full">
              <input
                type="text"
                placeholder="Search for listings..."
                className="block w-full rounded-md border-0 bg-primary py-1.5 pl-10 pr-3 text-white ring-1 ring-inset ring-primary-light focus:ring-2 focus:ring-inset focus:ring-primary-light sm:text-sm sm:leading-6"
              />
              <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                <SearchIcon className="h-5 w-5 text-gray-400" />
              </div>
            </div>
          </div>

          {/* Desktop Right Section: Notification */}
          <div className="hidden md:flex items-center">
            <NotificationBell />
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
                <MobileNavLinks />
                <div className="block px-3 py-2 rounded-md text-base font-medium text-white hover:bg-gray-700">
                  <UserProfile />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </nav>
  );
}

'use client';

import { useState } from 'react';
import Logo from './navigation/Logo';
import DesktopNavLinks from './navigation/DesktopNavLinks';
import NotificationBell from './navigation/NotificationBell';
import UserProfile from './navigation/UserProfile';
import MenuIcon from './navigation/MenuIcon';
import MobileNavLinks from './navigation/MobileNavLinks';

export default function Navigation() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  
  return (
    <nav className="bg-white shadow-md">
      <div className="container mx-auto px-4">
        {/* Desktop Navigation */}
        <div className="hidden md:flex items-center justify-between h-16">
          <div className="flex items-center space-x-8">
            <Logo />
            <DesktopNavLinks />
          </div>
          <div className="flex items-center space-x-4">
            <NotificationBell />
            <UserProfile />
          </div>
        </div>
        
        {/* Mobile Navigation */}
        <div className="md:hidden flex items-center justify-between h-16">
          <Logo />
          <button 
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="p-2 rounded-md text-gray-700"
            aria-label="Menu"
          >
            <MenuIcon />
          </button>
        </div>
        
        {/* Mobile Menu (Dropdown) */}
        {isMobileMenuOpen && (
          <div className="md:hidden bg-white border-t">
            <MobileNavLinks />
            <div className="p-4 border-t">
              <UserProfile />
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}

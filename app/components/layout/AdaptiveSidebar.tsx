'use client';

import { useState } from 'react';
import MenuIcon from '../navigation/MenuIcon.js'; // Reusing MenuIcon
import SidebarContent from './SidebarContent.js';

export default function AdaptiveSidebar() {
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  
  return (
    <>
      {/* Mobile Toggle Button */}
      <button
        onClick={() => setIsMobileOpen(true)}
        className="md:hidden fixed bottom-4 right-4 bg-primary text-white p-3 rounded-full shadow-lg z-40"
        aria-label="Open sidebar menu"
      >
        <MenuIcon />
      </button>
      
      {/* Mobile Sidebar (Drawer) */}
      {isMobileOpen && (
        <div className="md:hidden fixed inset-0 z-50">
          <div 
            className="absolute inset-0 bg-black bg-opacity-50"
            onClick={() => setIsMobileOpen(false)}
          />
          <div className="absolute right-0 top-0 h-full w-64 bg-white shadow-xl">
            <SidebarContent />
          </div>
        </div>
      )}
      
      {/* Desktop Sidebar */}
      <div className="hidden md:block w-64 border-r">
        <SidebarContent />
      </div>
    </>
  );
}

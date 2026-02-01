'use client';

import { useState } from 'react';
import Logo from './navigation/Logo';
import DesktopNavLinks from './navigation/DesktopNavLinks';
import NotificationBell from './navigation/NotificationBell';
import UserProfile from './navigation/UserProfile';
import MenuIcon from './navigation/MenuIcon';
import MobileNavLinks from './navigation/MobileNavLinks';
import {
  AppBar,
  Toolbar,
  IconButton,
  Box,
  Drawer,
  List,
  ListItem,
  ListItemText,
} from '@mui/material';

export default function Navigation() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const toggleDrawer = (open: boolean) => () => {
    setIsMobileMenuOpen(open);
  };

  return (
    <AppBar position="static" color="default" elevation={1}>
      <Toolbar>
        {/* Desktop Navigation */}
        <Box sx={{ flexGrow: 1, display: { xs: 'none', md: 'flex' }, alignItems: 'center' }}>
          <Logo />
          <Box sx={{ ml: 4 }}>
            <DesktopNavLinks />
          </Box>
        </Box>
        <Box sx={{ flexGrow: 1, display: { xs: 'none', md: 'flex' }, justifyContent: 'flex-end', alignItems: 'center' }}>
          <NotificationBell />
          <UserProfile />
        </Box>

        {/* Mobile Navigation */}
        <Box sx={{ flexGrow: 1, display: { xs: 'flex', md: 'none' }, justifyContent: 'space-between', alignItems: 'center' }}>
          <Logo />
          <IconButton
            edge="end"
            color="inherit"
            aria-label="menu"
            onClick={toggleDrawer(true)}
            sx={{ ml: 2 }}
          >
            <MenuIcon />
          </IconButton>
          <Drawer
            anchor="right"
            open={isMobileMenuOpen}
            onClose={toggleDrawer(false)}
          >
            <Box
              sx={{ width: 250 }}
              role="presentation"
              onClick={toggleDrawer(false)}
              onKeyDown={toggleDrawer(false)}
            >
              <List>
                <MobileNavLinks />
                <ListItem>
                  <UserProfile />
                </ListItem>
              </List>
            </Box>
          </Drawer>
        </Box>
      </Toolbar>
    </AppBar>
  );
}

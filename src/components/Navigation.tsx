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
  TextField,
  InputAdornment, // Add InputAdornment import
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search'; // Add SearchIcon import

export default function Navigation() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const toggleDrawer = (open: boolean) => () => {
    setIsMobileMenuOpen(open);
  };

  return (
    <AppBar position="static" color="primary" elevation={4}>
      <Toolbar sx={{ px: 2, justifyContent: 'space-between' }}>
        {/* Desktop Left Section: Logo and Nav Links */}
        <Box sx={{ display: { xs: 'none', md: 'flex' }, alignItems: 'center' }}>
          <Logo />
          <Box sx={{ ml: 4 }}>
            <DesktopNavLinks />
          </Box>
        </Box>

        {/* Search Bar for Desktop (Central) */}
        <Box
          sx={{
            flexGrow: 1,
            display: { xs: 'none', md: 'flex' },
            justifyContent: 'center',
            alignItems: 'center',
            maxWidth: '500px', // Limit search bar width
            mx: 2,
          }}
        >
          <TextField
            fullWidth
            variant="outlined"
            size="small"
            placeholder="Search for listings..."
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
          />
        </Box>

        {/* Desktop Right Section: Notification and User Profile */}
        <Box sx={{ display: { xs: 'none', md: 'flex' }, alignItems: 'center', ml: 2 }}>
          <NotificationBell />
          <UserProfile />
        </Box>

        {/* Mobile Navigation - Remains largely the same for now */}
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

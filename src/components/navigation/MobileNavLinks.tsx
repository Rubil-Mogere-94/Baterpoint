import { Link } from 'react-router-dom';
import MenuItem from '@mui/material/MenuItem';

export default function MobileNavLinks() {
  return (
    <>
      <MenuItem component={Link} to="/browse">
        Browse Listings
      </MenuItem>
      <MenuItem component={Link} to="/how-it-works">
        How it Works
      </MenuItem>
      <MenuItem component={Link} to="/pricing">
        Pricing
      </MenuItem>
    </>
  );
}

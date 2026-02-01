import Link from 'next/link';
import MenuItem from '@mui/material/MenuItem';

export default function MobileNavLinks() {
  return (
    <>
      <MenuItem component={Link} href="/browse">
        Browse Listings
      </MenuItem>
      <MenuItem component={Link} href="/how-it-works">
        How it Works
      </MenuItem>
      <MenuItem component={Link} href="/pricing">
        Pricing
      </MenuItem>
    </>
  );
}

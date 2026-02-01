import Link from 'next/link';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';

export default function DesktopNavLinks() {
  return (
    <Box sx={{ display: 'flex', gap: 2 }}>
      <Button component={Link} href="/browse" color="inherit">
        Browse Listings
      </Button>
      <Button component={Link} href="/how-it-works" color="inherit">
        How it Works
      </Button>
      <Button component={Link} href="/pricing" color="inherit">
        Pricing
      </Button>
    </Box>
  );
}

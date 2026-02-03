import { Link } from 'react-router-dom';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';

export default function DesktopNavLinks() {
  return (
    <Box sx={{ display: 'flex', gap: 2 }}>
      <Button component={Link} to="/browse" color="inherit">
        Browse Listings
      </Button>
      <Button component={Link} to="/how-it-works" color="inherit">
        How it Works
      </Button>
      <Button component={Link} to="/pricing" color="inherit">
        Pricing
      </Button>
    </Box>
  );
}

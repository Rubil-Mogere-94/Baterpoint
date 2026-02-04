import { Link } from 'react-router-dom';

export default function DesktopNavLinks() {
  return (
    <div className="hidden md:flex items-center space-x-4">
      <Link to="/browse" className="text-white hover:bg-primary-light px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200">
        Browse Listings
      </Link>
      <Link to="/how-it-works" className="text-white hover:bg-primary-light px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200">
        How it Works
      </Link>
      <Link to="/pricing" className="text-white hover:bg-primary-light px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200">
        Pricing
      </Link>
    </div>
  );
}

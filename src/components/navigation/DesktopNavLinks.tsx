import { Link, useLocation } from 'react-router-dom';

export default function DesktopNavLinks() {
  const location = useLocation();

  const getLinkClasses = (path: string) => {
    const isActive = location.pathname === path;
    return `px-3 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
      isActive
        ? 'bg-primary text-white shadow-md' // Active state
        : 'text-white hover:bg-primary-light hover:text-white' // Inactive and hover state
    }`;
  };

  return (
    <div className="hidden md:flex items-center space-x-4">
      <Link to="/browse" className={getLinkClasses('/browse')}>
        Browse Listings
      </Link>
      <Link to="/how-it-works" className={getLinkClasses('/how-it-works')}>
        How it Works
      </Link>
      <Link to="/pricing" className={getLinkClasses('/pricing')}>
        Pricing
      </Link>
    </div>
  );
}

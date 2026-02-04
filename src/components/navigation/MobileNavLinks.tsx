import { Link } from 'react-router-dom';

export default function MobileNavLinks() {
  return (
    <div className="px-2 pt-2 pb-3 space-y-1">
      <Link
        to="/browse"
        className="block px-3 py-2 rounded-md text-base font-medium text-white hover:bg-gray-700"
      >
        Browse Listings
      </Link>
      <Link
        to="/how-it-works"
        className="block px-3 py-2 rounded-md text-base font-medium text-white hover:bg-gray-700"
      >
        How it Works
      </Link>
      <Link
        to="/pricing"
        className="block px-3 py-2 rounded-md text-base font-medium text-white hover:bg-gray-700"
      >
        Pricing
      </Link>
    </div>
  );
}

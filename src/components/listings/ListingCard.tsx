import { Link } from 'react-router-dom';
import NetworkAwareImage from '@/components/media/NetworkAwareImage';
import { TouchButton } from '../buttons/TouchButton'; // Import the TouchButton

export interface Listing {
  id: number;
  title: string;
  description: string;
  price: string;
  category: string;
  tradeType: string;
  imageUrl?: string;
}

export default function ListingCard({ listing, className }: { listing: Listing, className?: string }) {
  return (
    <div className={`flex flex-col bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow duration-300 overflow-hidden cursor-pointer ${className}`}>
      <div className="relative w-full h-48 bg-neutral-100 flex items-center justify-center overflow-hidden">
        {listing.imageUrl ? (
          <NetworkAwareImage
            src={listing.imageUrl}
            alt={listing.title}
            className="w-full h-full object-cover"
          />
        ) : (
          <span className="text-neutral-400 text-sm">No Image Available</span>
        )}
      </div>
      <div className="p-4 flex-grow flex flex-col justify-between">
        <h3 className="text-lg font-semibold text-text-dark mb-2">
          {listing.title}
        </h3>
        <p className="text-sm text-text-DEFAULT mb-2 leading-tight">
          {listing.description.length > 70 ? listing.description.substring(0, 70) + '...' : listing.description}
        </p>
        <div className="flex justify-between items-center text-xs text-text-light mb-3">
          <span>
            Category: {listing.category}
          </span>
          <span className="capitalize">
            {listing.tradeType}
          </span>
        </div>
        <p className="text-xl font-bold text-text-dark mb-4">
          KES {parseFloat(listing.price).toLocaleString()}
        </p>
        <Link to={"/listings/" + listing.id}>
          <TouchButton className="w-full">
            View Details
          </TouchButton>
        </Link>
      </div>
    </div>
  );
}

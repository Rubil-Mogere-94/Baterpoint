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
    <div className={`flex flex-col bg-white rounded-xl shadow-xl hover:shadow-2xl transition-all duration-300 overflow-hidden cursor-pointer border border-transparent hover:border-primary-light ${className}`}>
      <div className="relative w-full h-48 bg-neutral-100 flex items-center justify-center overflow-hidden">
        {listing.imageUrl ? (
          <NetworkAwareImage
            src={listing.imageUrl}
            alt={listing.title}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="flex flex-col items-center justify-center w-full h-full text-neutral-500 bg-neutral-200">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span className="text-sm font-medium">No Image</span>
          </div>
        )}
      </div>
      <div className="p-4 flex-grow flex flex-col justify-between">
        <h3 className="text-xl font-bold text-text-dark mb-2">
          {listing.title}
        </h3>
        <p className="text-sm text-text-DEFAULT mb-3 line-clamp-2">
          {listing.description}
        </p>
        <div className="flex flex-wrap gap-2 mb-3">
          <span className="bg-neutral-100 text-neutral-600 text-xs font-semibold px-2.5 py-0.5 rounded-full">
            {listing.category}
          </span>
          <span className="bg-primary-light text-primary-dark text-xs font-semibold px-2.5 py-0.5 rounded-full capitalize">
            {listing.tradeType}
          </span>
        </div>
        <p className="text-2xl font-extrabold text-primary-dark mb-4">
          KES {parseFloat(listing.price).toLocaleString()}
        </p>
        <Link to={"/listings/" + listing.id}>
          <TouchButton className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-2 px-4 rounded transition-colors duration-200">
            View Details
          </TouchButton>
        </Link>
      </div>
    </div>
  );
}

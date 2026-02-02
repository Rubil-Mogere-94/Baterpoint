import { Button } from '@mui/material';
import NetworkAwareImage from '@/components/media/NetworkAwareImage'; // Assuming this component exists

export interface Listing {
  id: number;
  title: string;
  price: string;
  imageUrl?: string; // Added for actual image display
}

export default function ListingCard({ listing, className }: { listing: Listing, className?: string }) {
  return (
    <div className={`flex flex-col border rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300 ${className}`}>
      <div className="relative w-full h-48 overflow-hidden rounded-t-lg bg-gray-100 flex items-center justify-center">
        {listing.imageUrl ? (
          <NetworkAwareImage
            src={listing.imageUrl}
            alt={listing.title}
            fill
            style={{ objectFit: 'cover' }}
          />
        ) : (
          <span className="text-gray-400 text-sm">Image</span>
        )}
      </div>
      <div className="p-4 flex-grow flex flex-col justify-between">
        <h3 className="font-bold text-xl mb-2 text-gray-800">{listing.title}</h3>
        <p className="text-lg font-semibold text-blue-600 mb-4">{listing.price}</p>
        <Button variant="contained" color="primary" fullWidth>
          View Details
        </Button>
      </div>
    </div>
  );
}

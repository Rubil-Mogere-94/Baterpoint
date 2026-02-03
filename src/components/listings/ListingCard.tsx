import { Button, Typography } from '@mui/material';
import NetworkAwareImage from '@/components/media/NetworkAwareImage';

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
    <div className={`flex flex-col border rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300 ${className}`}>
      <div className="relative w-full h-48 overflow-hidden rounded-t-lg bg-gray-100 flex items-center justify-center">
        {listing.imageUrl ? (
          <NetworkAwareImage
            src={listing.imageUrl}
            alt={listing.title}
            className="w-full h-full"
            style={{ objectFit: 'cover' }}
          />
        ) : (
          <span className="text-gray-400 text-sm">No Image</span>
        )}
      </div>
      <div className="p-4 flex-grow flex flex-col justify-between">
        <Typography variant="h6" component="h3" className="font-bold mb-1 text-gray-800">
          {listing.title}
        </Typography>
        <Typography variant="body2" color="text.secondary" className="mb-2">
          {listing.description.length > 70 ? listing.description.substring(0, 67) + '...' : listing.description}
        </Typography>
        <div className="flex justify-between items-center mb-2">
          <Typography variant="body2" color="text.secondary">
            Category: {listing.category}
          </Typography>
          <Typography variant="body2" color="text.secondary" className="capitalize">
            {listing.tradeType}
          </Typography>
        </div>
        <Typography variant="subtitle1" component="p" className="text-lg font-semibold text-blue-600 mb-4">
          KES {parseFloat(listing.price).toLocaleString()}
        </Typography>
        <Button variant="contained" color="primary" fullWidth>
          View Details
        </Button>
      </div>
    </div>
  );
}

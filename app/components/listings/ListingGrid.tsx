import ListingCard from "./ListingCard";
import { Listing } from "./ListingCard";
import { Button } from '@mui/material'; // Import Material-UI Button

export default function ListingGrid({ listings }: { listings: Listing[] }) {
  return (
    <div className="container mx-auto px-4">
      {/* Grid adjusts based on screen size */}
      <div className="grid grid-cols-1 xs:grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
        {listings.map((listing) => (
          <ListingCard 
            key={listing.id} 
            listing={listing}
            className="h-full"
          />
        ))}
      </div>
      
      {/* Pagination - different on mobile vs desktop */}
      <div className="mt-8">
        <div className="hidden md:flex justify-center space-x-2">
          {/* Desktop pagination */}
          {[1,2,3,4,5].map(page => (
            <Button key={page} variant="outlined" color="primary">
              {page}
            </Button>
          ))}
        </div>
        <div className="md:hidden flex justify-between">
          {/* Mobile pagination */}
          <Button variant="outlined" color="primary">Previous</Button>
          <span className="py-2">Page 1 of 5</span>
          <Button variant="outlined" color="primary">Next</Button>
        </div>
      </div>
    </div>
  );
}

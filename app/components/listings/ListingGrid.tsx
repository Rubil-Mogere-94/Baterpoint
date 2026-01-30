import ListingCard from "./ListingCard.js";
import { Listing } from "./ListingCard.js";

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
            <button key={page} className="px-4 py-2 border rounded">
              {page}
            </button>
          ))}
        </div>
        <div className="md:hidden flex justify-between">
          {/* Mobile pagination */}
          <button className="px-4 py-2 border rounded">Previous</button>
          <span className="py-2">Page 1 of 5</span>
          <button className="px-4 py-2 border rounded">Next</button>
        </div>
      </div>
    </div>
  );
}

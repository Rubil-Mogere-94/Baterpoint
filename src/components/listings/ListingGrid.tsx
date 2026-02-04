import ListingCard from "./ListingCard";
import { Listing } from "./ListingCard";
import { TouchButton } from '../buttons/TouchButton'; // Import the TouchButton

export default function ListingGrid({ listings }: { listings: Listing[] }) {
  return (
    <div className="container mx-auto px-4 py-8">
      {/* Grid adjusts based on screen size */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6">
        {listings.map((listing) => (
          <ListingCard 
            key={listing.id} 
            listing={listing}
            className="h-full"
          />
        ))}
      </div>
      
      {/* Pagination - different on mobile vs desktop */}
      <div className="mt-12 flex justify-center">
        <div className="hidden md:flex items-center space-x-2">
          {/* Desktop pagination */}
          {[1,2,3,4,5].map(page => (
            <TouchButton 
              key={page} 
              className="px-4 py-2 bg-neutral-100 text-neutral-700 hover:bg-primary-light hover:text-white border border-neutral-300"
            >
              {page}
            </TouchButton>
          ))}
        </div>
        <div className="md:hidden flex justify-between w-full">
          {/* Mobile pagination */}
          <TouchButton className="px-4 py-2 bg-neutral-100 text-neutral-700 hover:bg-primary-light hover:text-white border border-neutral-300">
            Previous
          </TouchButton>
          <span className="py-2 text-neutral-700">Page 1 of 5</span>
          <TouchButton className="px-4 py-2 bg-neutral-100 text-neutral-700 hover:bg-primary-light hover:text-white border border-neutral-300">
            Next
          </TouchButton>
        </div>
      </div>
    </div>
  );
}

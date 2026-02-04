import { useEffect, useState } from "react";
import ListingGrid from "@/components/listings/ListingGrid";
import { Listing } from "@/components/listings/ListingCard";

export default function BrowsePage() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchListings = async () => {
      try {
        const response = await fetch('http://localhost:8000/listings/');
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data: Listing[] = await response.json();
        setListings(data);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchListings();
  }, []);

  return (
    <div className="py-8">
      <h2 className="text-3xl font-bold text-center text-text-dark mb-8">
        All Listings
      </h2>
      {loading && (
        <div className="flex justify-center items-center h-48">
          <svg className="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>
      )}
      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mx-auto max-w-lg mb-4" role="alert">
          <strong className="font-bold">Error:</strong>
          <span className="block sm:inline ml-2">{error}</span>
        </div>
      )}
      {!loading && !error && listings.length === 0 && (
        <p className="text-center text-text-DEFAULT text-lg">No listings found.</p>
      )}
      {!loading && !error && listings.length > 0 && (
        <ListingGrid listings={listings} />
      )}
    </div>
  );
}

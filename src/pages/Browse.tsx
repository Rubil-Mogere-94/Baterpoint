import { useEffect, useState, useCallback } from "react";
import ListingGrid from "@/components/listings/ListingGrid";
import { Listing } from "@/components/listings/ListingCard";

export default function BrowsePage() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchTerm, setSearchTerm] = useState("");

  // New state for filters and sorting
  const [category, setCategory] = useState('');
  const [tradeType, setTradeType] = useState('');
  const [sortBy, setSortBy] = useState('created_at');
  const [order, setOrder] = useState('desc');


  const fetchListings = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const url = new URL('http://localhost:8000/listings/');
      if (searchTerm) {
        url.searchParams.append('search', searchTerm);
      }
      // Add new params
      if (category) {
        url.searchParams.append('category', category);
      }
      if (tradeType) {
        url.searchParams.append('tradeType', tradeType);
      }
      if (sortBy) {
        url.searchParams.append('sortBy', sortBy);
        url.searchParams.append('order', order);
      }
      
      const response = await fetch(url.toString());
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data: any[] = await response.json();
      const mappedListings = data.map((listing: any) => ({
          id: listing.id,
          title: listing.title,
          description: listing.description,
          price: listing.cashPrice ? String(listing.cashPrice) : '0',
          category: listing.category,
          tradeType: listing.tradeType,
          imageUrl: listing.imageUrl,
        }));
      setListings(mappedListings);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [searchTerm, category, tradeType, sortBy, order]); // Add new dependencies

  useEffect(() => {
    fetchListings();
  }, [fetchListings]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSearchTerm(searchQuery);
  };

  const handleResetFilters = () => {
    setSearchQuery('');
    setSearchTerm('');
    setCategory('');
    setTradeType('');
    setSortBy('created_at');
    setOrder('desc');
  };

  return (
    <div className="py-8">
      <h2 className="text-3xl font-bold text-center text-text-dark mb-4">
        All Listings
      </h2>

      {/* Search Bar */}
      <form onSubmit={handleSearch} className="max-w-2xl mx-auto mb-4 px-4">
        <div className="relative">
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search for items..."
            className="w-full p-4 pr-20 rounded-full border-2 border-neutral-200 focus:ring-2 focus:ring-primary-dark focus:border-primary-dark transition-all duration-200"
          />
          <button type="submit" className="absolute top-1/2 right-2 -translate-y-1/2 bg-primary-dark hover:bg-primary text-white font-bold py-2.5 px-6 rounded-full transition-colors duration-200">
            Search
          </button>
        </div>
      </form>
      
      {/* Filters and Sorting */}
      <div className="max-w-4xl mx-auto mb-8 px-4 flex flex-wrap gap-4 items-center justify-center">
        {/* Category Filter */}
        <select value={category} onChange={e => setCategory(e.target.value)} className="p-2 border rounded-md">
            <option value="">All Categories</option>
            <option value="electronics">Electronics</option>
            <option value="phones">Phones & Tablets</option>
            <option value="agriculture">Agriculture</option>
            <option value="services">Services</option>
        </select>
        {/* Trade Type Filter */}
        <select value={tradeType} onChange={e => setTradeType(e.target.value)} className="p-2 border rounded-md">
            <option value="">All Trade Types</option>
            <option value="barter">Barter</option>
            <option value="cash">Cash</option>
            <option value="mixed">Mixed</option>
        </select>
        {/* Sort By */}
        <select value={sortBy} onChange={e => setSortBy(e.target.value)} className="p-2 border rounded-md">
            <option value="created_at">Date Posted</option>
            <option value="price">Price</option>
        </select>
        {/* Order */}
        <select value={order} onChange={e => setOrder(e.target.value)} className="p-2 border rounded-md">
            <option value="desc">Descending</option>
            <option value="asc">Ascending</option>
        </select>
        <button onClick={handleResetFilters} className="p-2 bg-gray-200 rounded-md">Reset</button>
      </div>

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
        <p className="text-center text-text-DEFAULT text-lg">
          {searchTerm ? `No listings found for "${searchTerm}".` : "No listings found."}
        </p>
      )}
      {!loading && !error && listings.length > 0 && (
        <ListingGrid listings={listings} />
      )}
    </div>
  );
}








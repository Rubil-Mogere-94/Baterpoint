import React, { useEffect, useState } from 'react';
import ListingCard from '../components/listings/ListingCard';
import { Listing } from '../components/listings/ListingCard';

const UserProfilePage = () => {
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchListings = async () => {
      const token = localStorage.getItem('access_token');
      if (!token) {
        setError('You are not authorized to view this page.');
        setLoading(false);
        return;
      }

      try {
        const response = await fetch('http://localhost:8000/users/me/listings', {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          throw new Error('Failed to fetch your listings.');
        }

        const data = await response.json();
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
    };

    fetchListings();
  }, []);

  if (loading) {
    return <div className="text-center p-8">Loading your listings...</div>;
  }

  if (error) {
    return <div className="text-red-500 text-center p-8">{error}</div>;
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">My Listings</h1>
      {listings.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {listings.map((listing) => (
            <ListingCard key={listing.id} listing={listing} />
          ))}
        </div>
      ) : (
        <div className="text-center p-8 border-2 border-dashed rounded-lg">
          <p className="text-lg text-gray-500">You have not created any listings yet.</p>
        </div>
      )}
    </div>
  );
};

export default UserProfilePage;
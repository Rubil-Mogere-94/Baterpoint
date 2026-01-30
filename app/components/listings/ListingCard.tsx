export interface Listing {
  id: number;
  title: string;
  price: string;
}

export default function ListingCard({ listing, className }: { listing: Listing, className: string }) {
  return (
    <div className={`border rounded-lg p-4 ${className}`}>
      <div className="h-32 bg-gray-200 rounded-md mb-4"></div>
      <h3 className="font-semibold text-lg">{listing.title}</h3>
      <p className="text-gray-600">{listing.price}</p>
    </div>
  );
}

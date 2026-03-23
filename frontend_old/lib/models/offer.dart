import 'listing.dart';

class Offer {
  final int id;
  final int buyerId;
  final int listingId;
  final double? offeredPrice;
  final String? offeredItem;
  final String status;
  final bool buyerConfirmed;
  final bool sellerConfirmed;
  final Listing? listing;

  Offer({
    required this.id,
    required this.buyerId,
    required this.listingId,
    this.offeredPrice,
    this.offeredItem,
    required this.status,
    this.buyerConfirmed = false,
    this.sellerConfirmed = false,
    this.listing,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'],
      buyerId: json['buyer_id'],
      listingId: json['listing_id'],
      offeredPrice: json['offered_price'] != null ? (json['offered_price'] as num).toDouble() : null,
      offeredItem: json['offered_item'],
      status: json['status'],
      buyerConfirmed: json['buyer_confirmed'] ?? false,
      sellerConfirmed: json['seller_confirmed'] ?? false,
      listing: json['listing'] != null ? Listing.fromJson(json['listing']) : null,
    );
  }
}

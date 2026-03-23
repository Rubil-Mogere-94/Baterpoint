// frontend/lib/models/deal.dart
import 'listing.dart';

class Deal {
  final int id;
  final int listingId;
  final int discountPercentage;
  final DateTime startTime;
  final DateTime endTime;
  final Listing listing;

  Deal({
    required this.id,
    required this.listingId,
    required this.discountPercentage,
    required this.startTime,
    required this.endTime,
    required this.listing,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'],
      listingId: json['listing_id'],
      discountPercentage: json['discount_percentage'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      listing: Listing.fromJson(json['listing']),
    );
  }
}

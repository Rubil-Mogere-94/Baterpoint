import 'package:flutter/material.dart';

class AuctionBid {
  final int id;
  final int auctionId;
  final int bidderId;
  final String bidderUsername;
  final double bidAmount;
  final DateTime timestamp;

  AuctionBid({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.bidderUsername,
    required this.bidAmount,
    required this.timestamp,
  });

  factory AuctionBid.fromJson(Map<String, dynamic> json) {
    return AuctionBid(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      auctionId: json['auction_id'] is int
          ? json['auction_id']
          : int.tryParse(json['auction_id'].toString()) ?? 0,
      bidderId: json['bidder_id'] is int
          ? json['bidder_id']
          : int.tryParse(json['bidder_id'].toString()) ?? 0,
      bidderUsername: json['bidder_username']?.toString() ?? 'Bidder #${json['bidder_id']}',
      bidAmount: (json['bid_amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AuctionItem {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String conditionType;
  final String? damageDetails;
  final List<String> recyclableMaterials;
  final double startingBid;
  final double currentBid;
  final double minIncrement;
  final int? highestBidderId;
  final String? highestBidderUsername;
  final int sellerId;
  final String? sellerUsername;
  final String status;
  final DateTime createdAt;
  final DateTime endsAt;
  final int totalBids;
  final bool isEnded;
  final List<AuctionBid> bids;

  AuctionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.conditionType,
    this.damageDetails,
    required this.recyclableMaterials,
    required this.startingBid,
    required this.currentBid,
    required this.minIncrement,
    this.highestBidderId,
    this.highestBidderUsername,
    required this.sellerId,
    this.sellerUsername,
    required this.status,
    required this.createdAt,
    required this.endsAt,
    required this.totalBids,
    required this.isEnded,
    this.bids = const [],
  });

  double get minNextBid => currentBid > 0 ? (currentBid + minIncrement) : startingBid;

  bool get hasEnded => isEnded || DateTime.now().isAfter(endsAt);

  String get timeLeftFormatted {
    if (hasEnded) return 'Auction Closed';
    final diff = endsAt.difference(DateTime.now());
    if (diff.isNegative) return 'Auction Closed';
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return '${diff.inDays}d ${hours}h left';
    }
    if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return '${diff.inHours}h ${mins}m left';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m left';
    }
    return '${diff.inSeconds}s left';
  }

  String get conditionLabel {
    switch (conditionType) {
      case 'damaged_repair':
        return 'Damaged (Repair)';
      case 'spare_parts':
        return 'Spare Parts Only';
      case 'recyclable':
        return 'Recyclable / E-Waste';
      case 'refurbishable':
        return 'Refurbishable';
      default:
        return 'Salvage';
    }
  }

  Color get conditionColor {
    switch (conditionType) {
      case 'damaged_repair':
        return const Color(0xFFE65100);
      case 'spare_parts':
        return const Color(0xFF6A1B9A);
      case 'recyclable':
        return const Color(0xFF2E7D32);
      case 'refurbishable':
        return const Color(0xFF0277BD);
      default:
        return const Color(0xFF455A64);
    }
  }

  factory AuctionItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawBids = json['bids'];
    final List<AuctionBid> parsedBids = [];
    if (rawBids is List) {
      for (final b in rawBids) {
        if (b is Map) {
          parsedBids.add(AuctionBid.fromJson(Map<String, dynamic>.from(b)));
        }
      }
    }

    final rawMaterials = json['recyclable_materials'];
    final List<String> materials = [];
    if (rawMaterials is List) {
      for (final m in rawMaterials) {
        materials.add(m.toString());
      }
    }

    return AuctionItem(
      id: id,
      title: json['title']?.toString() ?? 'Auction Item #$id',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? 'assets/images/bag_1.png',
      conditionType: json['condition_type']?.toString() ?? 'damaged_repair',
      damageDetails: json['damage_details']?.toString(),
      recyclableMaterials: materials,
      startingBid: (json['starting_bid'] as num?)?.toDouble() ?? 100.0,
      currentBid: (json['current_bid'] as num?)?.toDouble() ?? 0.0,
      minIncrement: (json['min_increment'] as num?)?.toDouble() ?? 50.0,
      highestBidderId: json['highest_bidder_id'] is int ? json['highest_bidder_id'] : null,
      highestBidderUsername: json['highest_bidder_username']?.toString(),
      sellerId: json['seller_id'] is int ? json['seller_id'] : 0,
      sellerUsername: json['seller_username']?.toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'].toString()) ??
              DateTime.now().add(const Duration(hours: 48))
          : DateTime.now().add(const Duration(hours: 48)),
      totalBids: (json['total_bids'] as num?)?.toInt() ?? parsedBids.length,
      isEnded: json['is_ended'] == true,
      bids: parsedBids,
    );
  }
}

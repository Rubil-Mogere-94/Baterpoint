import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../models/auction.dart';
import '../../services/api_service.dart';
import '../../services/currency_provider.dart';
import '../chat/chat_screen.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCondition = 'all';
  String? _selectedMaterial;
  bool _isLoading = true;
  List<AuctionItem> _auctions = [];
  Map<String, dynamic> _stats = {
    'total_active_auctions': 0,
    'total_bids_placed': 0,
    'salvage_items_diverted': 0,
    'recyclable_categories': <String>[],
  };

  final List<Map<String, String>> _conditionFilters = [
    {'key': 'all', 'label': 'All Salvage', 'icon': '♻️'},
    {'key': 'damaged_repair', 'label': 'Damaged (Repair)', 'icon': '🔧'},
    {'key': 'spare_parts', 'label': 'Spare Parts Only', 'icon': '🔩'},
    {'key': 'recyclable', 'label': 'Recyclable / E-Waste', 'icon': '🌱'},
    {'key': 'refurbishable', 'label': 'Refurbishable', 'icon': '✨'},
  ];

  final List<String> _popularMaterials = [
    'E-Waste',
    'Electronics',
    'Copper',
    'Scrap Metal',
    'Aluminum',
    'Timber',
    'Hardwood',
    'Plastics',
    'Optical Glass',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getAuctions(
          conditionType: _selectedCondition == 'all' ? null : _selectedCondition,
          recyclableMaterial: _selectedMaterial,
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        ),
        _apiService.getAuctionStats(),
      ]);

      if (mounted) {
        setState(() {
          _auctions = results[0] as List<AuctionItem>;
          _stats = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openBidSheet(AuctionItem auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BidModalSheet(
        auction: auction,
        apiService: _apiService,
        onBidSuccess: () {
          _loadData();
        },
      ),
    );
  }

  void _openCreateAuctionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateAuctionDialog(
        apiService: _apiService,
        onCreated: () => _loadData(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.recycling_rounded, color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Salvage & Recyclable Auctions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh Auctions',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Shopkeeper Desk',
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateAuctionDialog,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('List Salvage Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding),
          children: [
            // Eco Impact Dashboard Banner
            _buildEcoDashboard(currency),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorderColor),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadData(),
                decoration: InputDecoration(
                  hintText: 'Search damaged electronics, e-waste, scrap, parts...',
                  hintStyle: const TextStyle(fontSize: 13, color: kTextLightColor),
                  prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadData();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Condition Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _conditionFilters.map((f) {
                  final isSelected = _selectedCondition == f['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text('${f['icon']} ${f['label']}'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : kTextColor,
                      ),
                      selectedColor: const Color(0xFF2E7D32),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF2E7D32) : kBorderColor,
                        ),
                      ),
                      onSelected: (val) {
                        setState(() => _selectedCondition = f['key']!);
                        _loadData();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Recyclable Material Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: const Text('All Materials', style: TextStyle(fontSize: 11)),
                      backgroundColor: _selectedMaterial == null
                          ? const Color(0xFF00796B).withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      side: BorderSide(
                        color: _selectedMaterial == null ? const Color(0xFF00796B) : Colors.transparent,
                      ),
                      onPressed: () {
                        setState(() => _selectedMaterial = null);
                        _loadData();
                      },
                    ),
                  ),
                  ..._popularMaterials.map((mat) {
                    final isSelected = _selectedMaterial?.toLowerCase() == mat.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(mat, style: const TextStyle(fontSize: 11)),
                        backgroundColor: isSelected
                            ? const Color(0xFF00796B)
                            : Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : kTextColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF00796B) : Colors.transparent,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMaterial = isSelected ? null : mat;
                          });
                          _loadData();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Anti-Scam Shopkeeper Escrow Notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFFF57F17), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All auction deals are verified by the Barterpoint Shopkeeper desk. No direct seller messaging to prevent salvage payment fraud.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Auction Items Grid / List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
              )
            else if (_auctions.isEmpty)
              _buildEmptyState()
            else
              ..._auctions.map((item) => _buildAuctionCard(item, currency)),
            const SizedBox(height: 70), // Spacing for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildEcoDashboard(CurrencyProvider currency) {
    final active = _stats['total_active_auctions'] ?? _auctions.length;
    final totalBids = _stats['total_bids_placed'] ?? 0;
    final diverted = _stats['salvage_items_diverted'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Circular Salvage Market',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Repair • Extract Spare Parts • Recycle E-Waste',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Active Salvage', '$active items', Icons.gavel_rounded),
              Container(width: 1, height: 36, color: Colors.white24),
              _buildMetric('Bids Placed', '$totalBids bids', Icons.show_chart_rounded),
              Container(width: 1, height: 36, color: Colors.white24),
              _buildMetric('Saved from Landfill', '$diverted saved', Icons.restore_from_trash_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.recycling_rounded, size: 54, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'No matching salvage or recyclable auctions found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your condition filters or list the first damaged item for auction.',
            style: TextStyle(color: kTextLightColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _openCreateAuctionDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('List Damaged Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionCard(AuctionItem item, CurrencyProvider currency) {
    final highestBid = item.currentBid > 0 ? item.currentBid : item.startingBid;
    final highestBidFormatted = currency.formatKesEquivalent(highestBid);
    final minNextBidFormatted = currency.formatKesEquivalent(item.minNextBid);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and condition badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: item.imageUrl.startsWith('http')
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackImage(),
                        )
                      : Image.asset(
                          item.imageUrl.isNotEmpty ? item.imageUrl : 'assets/images/bag_1.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackImage(),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.conditionColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.handyman_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        item.conditionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.hasEnded ? Colors.red.shade800 : Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.hasEnded ? Icons.timer_off_rounded : Icons.timer_outlined,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.timeLeftFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 6),

                // Damage defect warning box
                if (item.damageDetails != null && item.damageDetails!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE65100)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Damage note: ${item.damageDetails}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFBF360C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Recyclable materials tags
                if (item.recyclableMaterials.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.recyclableMaterials.map((mat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Text(
                          '#$mat',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),

                // Bidding Status Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.totalBids > 0 ? 'Current Highest Bid' : 'Starting Bid',
                            style: const TextStyle(fontSize: 11, color: kTextLightColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            highestBidFormatted,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            'Min next: $minNextBidFormatted',
                            style: const TextStyle(fontSize: 10.5, color: kTextLightColor),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kBorderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.gavel_rounded, size: 14, color: kPrimaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.totalBids} ${item.totalBids == 1 ? "bid" : "bids"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: kTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (item.highestBidderUsername != null)
                            Text(
                              'Leader: ${item.highestBidderUsername}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons: Bid & Ask Shopkeeper
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: item.hasEnded ? null : () => _openBidSheet(item),
                        icon: const Icon(Icons.gavel_rounded, size: 18),
                        label: Text(item.hasEnded ? 'Auction Closed' : 'Place Bid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          );
                        },
                        icon: const Icon(Icons.contact_support_outlined, size: 16),
                        label: const Text('Inquire', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextColor,
                          side: const BorderSide(color: kBorderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.hardware_rounded, size: 48, color: Colors.grey),
      ),
    );
  }
}

class _BidModalSheet extends StatefulWidget {
  final AuctionItem auction;
  final ApiService apiService;
  final VoidCallback onBidSuccess;

  const _BidModalSheet({
    required this.auction,
    required this.apiService,
    required this.onBidSuccess,
  });

  @override
  State<_BidModalSheet> createState() => _BidModalSheetState();
}

class _BidModalSheetState extends State<_BidModalSheet> {
  late TextEditingController _amountController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.auction.minNextBid.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addIncrement(double inc) {
    final current = double.tryParse(_amountController.text) ?? widget.auction.minNextBid;
    setState(() {
      _amountController.text = (current + inc).toStringAsFixed(0);
    });
  }

  Future<void> _submitBid() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < widget.auction.minNextBid) {
      setState(() {
        _errorMessage = 'Bid must be at least KSh ${widget.auction.minNextBid.toStringAsFixed(0)}';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.placeBid(widget.auction.id, amount);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text('🎉 Bid of KSh ${amount.toStringAsFixed(0)} placed successfully!'),
          ),
        );
        widget.onBidSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.auction.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Minimum Required Bid: ${currency.formatKesEquivalent(widget.auction.minNextBid)}',
                      style: const TextStyle(color: kTextLightColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Increment Buttons
          const Text('Quick Increment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [50.0, 100.0, 250.0, 500.0].map((inc) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: () => _addIncrement(inc),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      '+${inc.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom Amount Field
          const Text('Your Bid Amount (KES)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            decoration: InputDecoration(
              prefixText: 'KSh ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: kBackgroundColor,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 14),

          // Escrow protection statement
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Buyer Protection: Winning bids are escrow-verified at the Barterpoint Shopkeeper desk before settlement.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBid,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirm & Place Bid',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAuctionDialog extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onCreated;

  const _CreateAuctionDialog({
    required this.apiService,
    required this.onCreated,
  });

  @override
  State<_CreateAuctionDialog> createState() => _CreateAuctionDialogState();
}

class _CreateAuctionDialogState extends State<_CreateAuctionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _damageController = TextEditingController();
  final _materialsController = TextEditingController();
  final _startBidController = TextEditingController(text: '100');
  final _minIncController = TextEditingController(text: '50');
  final _hoursController = TextEditingController(text: '48');

  String _conditionType = 'damaged_repair';
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _damageController.dispose();
    _materialsController.dispose();
    _startBidController.dispose();
    _minIncController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final materials = _materialsController.text
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    try {
      await widget.apiService.createAuction({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'image_url': 'assets/images/bag_1.png',
        'condition_type': _conditionType,
        'damage_details': _damageController.text.trim().isEmpty ? null : _damageController.text.trim(),
        'recyclable_materials': materials,
        'starting_bid': double.tryParse(_startBidController.text) ?? 100.0,
        'min_increment': double.tryParse(_minIncController.text) ?? 50.0,
        'duration_hours': int.tryParse(_hoursController.text) ?? 48,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E7D32),
            content: Text('🎉 Salvage auction listed successfully!'),
          ),
        );
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.recycling_rounded, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('List Damaged / Recyclable Item', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Broken Laptop for Parts'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _conditionType,
                decoration: const InputDecoration(labelText: 'Condition Classification'),
                items: const [
                  DropdownMenuItem(value: 'damaged_repair', child: Text('Damaged (Needs Repair)')),
                  DropdownMenuItem(value: 'spare_parts', child: Text('Spare Parts Only')),
                  DropdownMenuItem(value: 'recyclable', child: Text('Recyclable / E-Waste')),
                  DropdownMenuItem(value: 'refurbishable', child: Text('Refurbishable')),
                ],
                onChanged: (val) => setState(() => _conditionType = val!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _damageController,
                decoration: const InputDecoration(
                  labelText: 'Exact Damage / Flaw Details',
                  hintText: 'e.g. Screen cracked, power board working',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _materialsController,
                decoration: const InputDecoration(
                  labelText: 'Recyclable Materials (comma-separated)',
                  hintText: 'e.g. Copper, Aluminum, E-Waste',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startBidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Starting Bid (KES)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _minIncController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Increment (KES)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'More details for bidders'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Start Auction'),
        ),
      ],
    );
  }
}

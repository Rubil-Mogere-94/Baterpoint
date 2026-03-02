// frontend/lib/screens/explore_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import 'create_listing_screen.dart';
import '../widgets/listing_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ListingService _listingService = ListingService();
  List<Listing> _listings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _selectedTradeType;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  Timer? _debounce;
  
  final ScrollController _scrollController = ScrollController();
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Vehicles',
    'Home',
    'Fashion',
    'Sports',
    'Services',
    'Other'
  ];

  final List<String> _tradeTypes = ['Both', 'Cash Only', 'Barter Only'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchListings();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading && !_isFetchingMore && _hasMore) {
      _fetchListings(reset: false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchListings({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _skip = 0;
        _hasMore = true;
        _listings.clear();
      });
    } else {
      if (_isFetchingMore || !_hasMore) return;
      setState(() => _isFetchingMore = true);
    }
    
    try {
      final newListings = await _listingService.fetchListings(
        search: _searchQuery,
        category: _selectedCategory,
        tradeType: _selectedTradeType == 'Both' ? null : _selectedTradeType,
        sortBy: _sortBy,
        order: _sortOrder,
        skip: _skip,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _listings = newListings;
          } else {
            _listings.addAll(newListings);
          }
          _skip += newListings.length;
          _hasMore = newListings.length == _limit;
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading listings: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        _searchQuery = query;
        _fetchListings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _fetchListings(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 140.0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Explore Trades',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort_rounded, color: Colors.white),
                  onSelected: (value) {
                    setState(() {
                      if (value == 'price_asc') {
                        _sortBy = 'price';
                        _sortOrder = 'asc';
                      } else if (value == 'price_desc') {
                        _sortBy = 'price';
                        _sortOrder = 'desc';
                      } else {
                        _sortBy = 'created_at';
                        _sortOrder = 'desc';
                      }
                    });
                    _fetchListings();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'newest', child: Text('Newest First')),
                    const PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                    const PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _fetchListings();
                            },
                            backgroundColor: Colors.white,
                            selectedColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text('Accepting:', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        ..._tradeTypes.map((type) {
                          final isSelected = (_selectedTradeType ?? 'Both') == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type, style: TextStyle(fontSize: 12)),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedTradeType = type;
                                  });
                                  _fetchListings();
                                }
                              },
                              backgroundColor: Colors.white,
                              selectedColor: theme.colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: isSelected ? theme.colorScheme.secondary : Colors.grey.shade600,
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_listings.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No trades found',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = _listings[index];
                      return ListingCard(listing: listing);
                    },
                    childCount: _listings.length,
                  ),
                ),
              ),
            if (_isFetchingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingScreen()),
          );
          if (result == true) {
            _fetchListings();
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

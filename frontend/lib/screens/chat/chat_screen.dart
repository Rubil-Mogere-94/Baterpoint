import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';
import '../../services/messaging_service.dart';
import '../details/components/product_comments_section.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _inboxFuture;
  late Future<List<Map<String, dynamic>>> _publicThreadsFuture;
  late Future<Map<String, dynamic>?> _shopkeeperFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _inboxFuture = _apiService.getInbox();
    _publicThreadsFuture = _apiService.getPublicThreads();
    _shopkeeperFuture = _apiService.getShopkeeper();
  }

  Future<void> _refresh() async {
    setState(() => _loadData());
    try {
      await Future.wait([_inboxFuture, _publicThreadsFuture, _shopkeeperFuture]);
    } catch (_) {}
  }

  Future<void> _openShopkeeperDesk() async {
    final shopkeeper = await _apiService.getShopkeeper();
    final shopkeeperId = (shopkeeper?['id'] as num?)?.toInt() ?? 1;
    final shopkeeperAvatar = (shopkeeper?['avatar_url'] ?? '').toString();

    if (!mounted) return;
    _openChatModal(
      otherUserId: shopkeeperId,
      name: '🏪 Barterpoint Shopkeeper (Mweka Duka)',
      message: 'Karibu Barterpoint Shop! I am your verified Shopkeeper. How can I assist with your trades or items today?',
      avatar: shopkeeperAvatar.isNotEmpty ? shopkeeperAvatar : getDiceBearAvatar('Shopkeeper'),
      isShopkeeper: true,
    );
  }

  void _openProductCommentsModal(int productId, String title) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SizedBox(
          height: MediaQuery.of(modalContext).size.height * 0.85,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(modalContext).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kBorderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ProductPublicCommentsSection(
                    productId: productId,
                    productTitle: title,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barterpoint Shop Desk & Comments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Dawati la Mweka Duka • Maoni ya Bidhaa', style: TextStyle(fontSize: 11, color: kTextLightColor)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: kTextLightColor,
          indicatorColor: kPrimaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.storefront_rounded, size: 20), text: 'Shopkeeper Desk'),
            Tab(icon: Icon(Icons.forum_rounded, size: 20), text: 'Public Inquiries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Shopkeeper Desk & Store Channel
          RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Consignment Shop Anti-Scam Shield Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_rounded, color: kPrimaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consignment Store Rule • No Private Supplier DMs',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryColor),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Barterpoint operates like a store: buyers do not transact directly with third-party suppliers in secret. The Shopkeeper inspects items, coordinates barters, and secures escrow.',
                              style: TextStyle(fontSize: 12, color: kTextColor, height: 1.35),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '🇰🇪 Wanunuzi huwasiliana na Mweka Duka pekee ili kuepuka walaghai na matapeli.',
                              style: TextStyle(fontSize: 11, color: kTextLightColor, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Action: Open Official Shopkeeper Desk
                Card.filled(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                              backgroundImage: NetworkImage(getDiceBearAvatar('Shopkeeper')),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Barterpoint Shopkeeper',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.verified_rounded, color: kPrimaryColor, size: 16),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Mweka Duka • Official Escrow & Trade Manager',
                                    style: TextStyle(fontSize: 12, color: kTextLightColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Have questions about an item swap, official trade approval, or order handover? Chat directly with the verified on-duty Shopkeeper.',
                          style: TextStyle(fontSize: 12, color: kTextColor, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _openShopkeeperDesk,
                            icon: const Icon(Icons.chat_rounded, size: 18),
                            label: const Text('Open Shopkeeper Desk (Wasiliana na Mweka Duka)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Official Notices & Thread History
                const Text(
                  'Recent Store Conversations & Notices',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _inboxFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: kSurfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorderColor.withValues(alpha: 0.5)),
                        ),
                        child: const Center(
                          child: Text(
                            'No prior conversations. Tap the Shopkeeper Desk above to get verified assistance.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: kTextLightColor),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: list.map((item) {
                        final name = (item['other_user_username'] ?? 'Shopkeeper').toString();
                        final message = (item['last_message'] ?? '').toString();
                        final unread = (item['unread_count'] as num?)?.toInt() ?? 0;
                        final avatar = (item['other_user_avatar'] ?? '').toString();
                        return Card.outlined(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                              backgroundImage: NetworkImage(
                                avatar.startsWith('http') ? avatar : getDiceBearAvatar(name),
                              ),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            trailing: unread > 0
                                ? CircleAvatar(
                                    radius: 12,
                                    backgroundColor: kPrimaryColor,
                                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                  )
                                : const Icon(Icons.chevron_right_rounded, color: kTextLightColor),
                            onTap: () => _openChatModal(
                              otherUserId: (item['other_user_id'] as num?)?.toInt() ?? 0,
                              name: name,
                              message: message,
                              avatar: avatar,
                              isShopkeeper: name.contains('Shopkeeper'),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // TAB 2: Public Item Inquiries & Discussions
          RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _publicThreadsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final threads = snapshot.data ?? [];
                if (threads.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(28),
                    children: const [
                      SizedBox(height: 60),
                      Icon(Icons.forum_outlined, size: 64, color: kTextLightColor),
                      SizedBox(height: 16),
                      Center(
                        child: Text('No public item inquiries yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Public comments and questions on items will appear here for all shoppers to see.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kTextLightColor, height: 1.45, fontSize: 13),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = threads[index];
                    final title = (item['title'] ?? 'Product').toString();
                    final count = (item['comment_count'] as num?)?.toInt() ?? 0;
                    final lastMsg = (item['last_comment'] ?? '').toString();
                    final img = (item['image_url'] ?? '').toString();
                    final listingId = (item['listing_id'] as num?)?.toInt() ?? 0;

                    return Card.outlined(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: img.isNotEmpty
                                      ? Image.network(img, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40))
                                      : const Icon(Icons.image, size: 40),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('$count public comments', style: const TextStyle(fontSize: 10, color: kPrimaryColor, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text('• Public Shelf', style: TextStyle(fontSize: 10, color: kTextLightColor)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (lastMsg.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  'Latest inquiry: "$lastMsg"',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.forum_rounded, size: 16),
                                label: const Text('View & Join Public Comments'),
                                onPressed: () => _openProductCommentsModal(listingId, title),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openChatModal({
    required int otherUserId,
    required String name,
    required String message,
    required String avatar,
    bool isShopkeeper = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return _ChatConversationSheet(
          otherUserId: otherUserId,
          name: name,
          initialMessage: message,
          avatar: avatar,
          isShopkeeper: isShopkeeper,
          onRefresh: _refresh,
        );
      },
    );
  }
}

class _ChatConversationSheet extends StatefulWidget {
  final int otherUserId;
  final String name;
  final String initialMessage;
  final String avatar;
  final bool isShopkeeper;
  final VoidCallback onRefresh;

  const _ChatConversationSheet({
    required this.otherUserId,
    required this.name,
    required this.initialMessage,
    required this.avatar,
    this.isShopkeeper = false,
    required this.onRefresh,
  });

  @override
  State<_ChatConversationSheet> createState() => _ChatConversationSheetState();
}

class _ChatConversationSheetState extends State<_ChatConversationSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loadingMessages = true;
  final Map<int, String> _translations = {};
  final Set<int> _translatingIndexes = {};
  String? _draftTranslation;
  bool _isTranslatingDraft = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() => _loadingMessages = true);
    if (widget.otherUserId > 0) {
      final thread = await _apiService.getConversation(widget.otherUserId);
      if (thread.isNotEmpty) {
        if (mounted) {
          setState(() {
            _messages = thread;
            _loadingMessages = false;
          });
        }
        return;
      }
    }
    // Fallback if no backend messages yet
    if (mounted) {
      setState(() {
        _messages = [
          {
            'sender_id': widget.otherUserId,
            'message_content': widget.initialMessage,
            'is_read': true,
          }
        ];
        _loadingMessages = false;
      });
    }
  }

  Future<void> _toggleTranslation(int index, String text) async {
    if (_translations.containsKey(index)) {
      setState(() => _translations.remove(index));
      return;
    }

    setState(() => _translatingIndexes.add(index));
    final result = await MessagingService.smartTranslate(text: text);
    if (mounted) {
      setState(() {
        _translatingIndexes.remove(index);
        if (result != null) {
          _translations[index] = '${result.targetLabel}: "${result.translated}"';
        } else {
          _translations[index] = 'Translation unavailable';
        }
      });
    }
  }

  Future<void> _translateDraft() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTranslatingDraft = true);
    final result = await MessagingService.smartTranslate(text: text);
    if (mounted) {
      setState(() {
        _isTranslatingDraft = false;
        _draftTranslation = result?.translated;
      });
    }
  }

  void _applyQuickPhrase(BarterPhrase phrase) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (phraseContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${phrase.icon} Choose Sending Language',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                title: Text(phrase.english, style: const TextStyle(fontSize: 14)),
                subtitle: const Text('English only'),
                onTap: () {
                  Navigator.pop(phraseContext);
                  _controller.text = phrase.english;
                },
              ),
              ListTile(
                leading: const Text('🇰🇪', style: TextStyle(fontSize: 22)),
                title: Text(phrase.swahili, style: const TextStyle(fontSize: 14)),
                subtitle: const Text('Kiswahili pekee'),
                onTap: () {
                  Navigator.pop(phraseContext);
                  _controller.text = phrase.swahili;
                },
              ),
              ListTile(
                leading: const Text('🌐', style: TextStyle(fontSize: 22)),
                title: Text(phrase.formatBilingual(), style: const TextStyle(fontSize: 13, height: 1.3)),
                subtitle: const Text('Bilingual (Both English & Kiswahili) • Recommended'),
                onTap: () {
                  Navigator.pop(phraseContext);
                  _controller.text = phrase.formatBilingual();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = (textToSend ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    // 1. Moderate profanity / scams with PurgoMalum
    final cleaned = await MessagingService.filterProfanity(text);

    // 2. Persist to backend if other user exists
    if (widget.otherUserId > 0) {
      await _apiService.sendChatMessage(
        recipientId: widget.otherUserId,
        messageContent: cleaned,
      );
    }

    // 3. Dispatch instant alert via ntfy.sh
    await MessagingService.sendNtfyAlert(
      topic: 'baterpoint-user-${widget.otherUserId > 0 ? widget.otherUserId : widget.name}',
      title: 'Message from Baterpoint Trader',
      body: cleaned,
      tags: ['speech_balloon', 'handshake'],
    );

    if (mounted) {
      setState(() {
        _messages.add({
          'sender_id': 0, // 0 represents current user locally
          'message_content': cleaned,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _controller.clear();
        _draftTranslation = null;
        _isSending = false;
      });
      widget.onRefresh();
      if (widget.isShopkeeper || widget.name.contains('Shopkeeper')) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _loadThread();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final avatarUrl = widget.avatar.startsWith('http')
        ? widget.avatar
        : getDiceBearAvatar(widget.name);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Header: Peer Trader & Bilingual Status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimaryColor.withValues(alpha: 0.12),
                  backgroundImage: NetworkImage(avatarUrl),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const Row(
                        children: [
                          Text('🇰🇪 Kiswahili', style: TextStyle(fontSize: 11, color: kSecondaryColor, fontWeight: FontWeight.w600)),
                          Text(' ⇄ ', style: TextStyle(fontSize: 11, color: kTextLightColor)),
                          Text('🇬🇧 English', style: TextStyle(fontSize: 11, color: kPrimaryColor, fontWeight: FontWeight.w600)),
                          Text(' • Live translation', style: TextStyle(fontSize: 11, color: kTextLightColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Public Inquiry & Official Verification Shield
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 14, color: kPrimaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.isShopkeeper || widget.name.contains('Shopkeeper')
                          ? '🏪 Barterpoint Official Shopkeeper Channel • Escrow & Inspection Protected'
                          : 'Public Item Channel • Trades strictly require Shopkeeper Official Approval',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            // Message Thread with Inline Translation
            Expanded(
              child: _loadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['sender_id'] != widget.otherUserId;
                        final content = (msg['message_content'] ?? '').toString();
                        final isTranslating = _translatingIndexes.contains(index);
                        final translation = _translations[index];

                        final detected = MessagingService.detectLanguage(content);
                        final targetLabel = detected == 'sw' ? 'Translate to English 🇬🇧' : 'Tafsiri kwa Kiswahili 🇰🇪';

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? kPrimaryColor : kBackgroundColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              ),
                              border: isMe ? null : Border.all(color: kBorderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : kTextColor,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                                // Inline Translated Box
                                if (translation != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : kSurfaceColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isMe
                                            ? Colors.white30
                                            : kSecondaryColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.translate_rounded,
                                          size: 14,
                                          color: isMe ? Colors.white70 : kSecondaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            translation,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: isMe ? Colors.white : kTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                // Translation Toggle Button
                                InkWell(
                                  onTap: isTranslating ? null : () => _toggleTranslation(index, content),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isTranslating)
                                          SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: isMe ? Colors.white70 : kPrimaryColor,
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.g_translate_rounded,
                                            size: 13,
                                            color: isMe ? Colors.white70 : kTextLightColor,
                                          ),
                                        const SizedBox(width: 4),
                                        Text(
                                          translation != null ? 'Hide translation' : targetLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isMe ? Colors.white70 : kPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Quick Barter Phrases (Misemo ya Kubadilishana)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MessagingService.quickBarterPhrases.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final phrase = MessagingService.quickBarterPhrases[idx];
                  return ActionChip(
                    avatar: Text(phrase.icon, style: const TextStyle(fontSize: 13)),
                    label: Text(
                      '${phrase.english} / ${phrase.swahili}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: kSurfaceColor,
                    side: const BorderSide(color: kBorderColor),
                    onPressed: () => _applyQuickPhrase(phrase),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Live Draft Translation Preview
            if (_draftTranslation != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Translation: "$_draftTranslation"',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        setState(() {
                          _controller.text = _draftTranslation!;
                          _draftTranslation = null;
                        });
                      },
                      child: const Text('Use', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        setState(() {
                          _controller.text = '${_controller.text}\n[Kiswahili/English: $_draftTranslation]';
                          _draftTranslation = null;
                        });
                      },
                      child: const Text('Both', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            // Reply Input Row with Live Translation Action
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    onChanged: (val) {
                      if (_draftTranslation != null) {
                        setState(() => _draftTranslation = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Type in English or Kiswahili…',
                      hintStyle: const TextStyle(fontSize: 13, color: kTextLightColor),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: kBorderColor),
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Translate draft (Tafsiri)',
                        icon: _isTranslatingDraft
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.g_translate_rounded, color: kSecondaryColor, size: 20),
                        onPressed: _isTranslatingDraft ? null : _translateDraft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    color: Colors.white,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    onPressed: _isSending ? null : () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


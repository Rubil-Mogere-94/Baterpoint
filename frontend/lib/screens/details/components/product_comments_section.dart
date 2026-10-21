import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../services/api_service.dart';
import '../../../services/messaging_service.dart';

class ProductPublicCommentsSection extends StatefulWidget {
  final int productId;
  final String productTitle;

  const ProductPublicCommentsSection({
    super.key,
    required this.productId,
    required this.productTitle,
  });

  @override
  State<ProductPublicCommentsSection> createState() => _ProductPublicCommentsSectionState();
}

class _ProductPublicCommentsSectionState extends State<ProductPublicCommentsSection> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  final Map<int, String> _translations = {};
  final Set<int> _translatingIds = {};
  String? _draftTranslation;
  bool _isTranslatingDraft = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getListingComments(widget.productId);
    if (mounted) {
      setState(() {
        _comments = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTranslation(int commentId, String text) async {
    if (_translations.containsKey(commentId)) {
      setState(() => _translations.remove(commentId));
      return;
    }
    setState(() => _translatingIds.add(commentId));
    final res = await MessagingService.smartTranslate(text: text);
    if (mounted) {
      setState(() {
        _translatingIds.remove(commentId);
        if (res != null) {
          _translations[commentId] = '${res.targetLabel}: "${res.translated}"';
        } else {
          _translations[commentId] = 'Translation unavailable';
        }
      });
    }
  }

  Future<void> _translateDraft() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isTranslatingDraft = true);
    final res = await MessagingService.smartTranslate(text: text);
    if (mounted) {
      setState(() {
        _isTranslatingDraft = false;
        _draftTranslation = res?.translated;
      });
    }
  }

  Future<void> _postComment([String? presetText]) async {
    final text = (presetText ?? _commentController.text).trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);

    // 1. Scam & profanity filter
    final cleanText = await MessagingService.filterProfanity(text);

    // 2. Post to backend
    final res = await _apiService.postListingComment(widget.productId, cleanText);
    if (mounted) {
      if (res != null) {
        setState(() {
          _comments.add(res);
          _commentController.clear();
          _draftTranslation = null;
          _isPosting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Public question posted. Visible to all shoppers.')),
        );
      } else {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post inquiry. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.forum_rounded, color: kPrimaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Public Inquiries & Comments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_comments.length} questions',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Maoni na Maswali ya Wazi • Hakuna Ujumbe wa Faragha',
          style: TextStyle(fontSize: 11, color: kTextLightColor),
        ),
        const SizedBox(height: 10),

        // Shop Model Explanation Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.storefront_rounded, size: 20, color: Color(0xFF0284C7)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supervised Consignment Shop Model',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Buyers do not privately contact suppliers. All product inquiries are public for transparency. Trade swaps are officially vetted and approved by the Barterpoint Shopkeeper.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Comments List
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor.withValues(alpha: 0.5)),
            ),
            child: const Column(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 36, color: kTextLightColor),
                SizedBox(height: 8),
                Text(
                  'No public questions yet.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextColor),
                ),
                SizedBox(height: 4),
                Text(
                  'Ask about item condition, inspection, or barter preferences below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: kTextLightColor),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final comment = _comments[idx];
              final commentId = (comment['id'] as num?)?.toInt() ?? idx;
              final author = (comment['sender_username'] ?? 'Shopper').toString();
              final isOfficial = comment['is_official'] == true || author == 'Shopkeeper';
              final content = (comment['message_content'] ?? '').toString();
              final translation = _translations[commentId];
              final isTranslating = _translatingIds.contains(commentId);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOfficial ? const Color(0xFFF0FDF4) : kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOfficial ? const Color(0xFFBBF7D0) : kBorderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isOfficial ? kPrimaryColor : kBorderColor,
                          backgroundImage: NetworkImage(getDiceBearAvatar(author)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          author,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOfficial ? kPrimaryColor : kTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isOfficial)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 10, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'Shopkeeper Official',
                                  style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kBorderColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Public Shopper',
                              style: TextStyle(fontSize: 9, color: kTextLightColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content,
                      style: const TextStyle(fontSize: 13, color: kTextColor, height: 1.35),
                    ),
                    if (translation != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kSecondaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.translate_rounded, size: 12, color: kSecondaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                translation,
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: kTextColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: isTranslating ? null : () => _toggleTranslation(commentId, content),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTranslating)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: kPrimaryColor),
                            )
                          else
                            const Icon(Icons.g_translate_rounded, size: 12, color: kTextLightColor),
                          const SizedBox(width: 4),
                          Text(
                            translation != null ? 'Hide translation' : 'Translate / Tafsiri 🌐',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),

        // Quick barter chips
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MessagingService.quickBarterPhrases.take(4).length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final phrase = MessagingService.quickBarterPhrases[idx];
              return ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: Text(phrase.icon, style: const TextStyle(fontSize: 11)),
                label: Text(phrase.english, style: const TextStyle(fontSize: 10)),
                onPressed: () => _postComment(phrase.formatBilingual()),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Live draft translation preview
        if (_draftTranslation != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Translation: "$_draftTranslation"',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20)),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    setState(() {
                      _commentController.text = _draftTranslation!;
                      _draftTranslation = null;
                    });
                  },
                  child: const Text('Use', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        // Post Public Question Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ask a public question (Uliza swali hadharani)…',
                  hintStyle: const TextStyle(fontSize: 12, color: kTextLightColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Translate draft (Tafsiri)',
                    icon: _isTranslatingDraft
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.g_translate_rounded, color: kSecondaryColor, size: 18),
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
                icon: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                onPressed: _isPosting ? null : () => _postComment(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

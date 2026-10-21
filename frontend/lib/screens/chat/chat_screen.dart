import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';
import '../../services/messaging_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _inboxFuture;

  @override
  void initState() {
    super.initState();
    _inboxFuture = _apiService.getInbox();
  }

  Future<void> _refresh() async {
    setState(() => _inboxFuture = _apiService.getInbox());
    try {
      await _inboxFuture;
    } catch (_) {
      // FutureBuilder presents the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _inboxFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 120),
                const Icon(Icons.cloud_off_rounded, size: 48, color: kTextLightColor),
                const SizedBox(height: 12),
                const Center(child: Text('Messages could not be loaded.')),
                Center(
                  child: TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ),
              ]);
            }
            final conversations = snapshot.data ?? <Map<String, dynamic>>[];
            if (conversations.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.forum_outlined, size: 64, color: kTextLightColor),
                  SizedBox(height: 16),
                  Center(
                    child: Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'When another trader messages you, the conversation will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextLightColor, height: 1.45),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kDefaultPadding),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = conversations[index];
                final name = (item['other_user_username'] ?? 'Trader').toString();
                final message = (item['last_message'] ?? 'No message preview').toString();
                final unread = (item['unread_count'] as num?)?.toInt() ?? 0;
                final avatar = (item['other_user_avatar'] ?? '').toString();
                return Card.outlined(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryColor.withValues(alpha: 0.12),
                      backgroundImage: NetworkImage(
                        avatar.startsWith('http')
                            ? avatar
                            : getDiceBearAvatar(name),
                      ),
                      onBackgroundImageError: (_, __) {},
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 13,
                            backgroundColor: kPrimaryColor,
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          )
                        : const Icon(Icons.chevron_right_rounded, color: kTextLightColor),
                    onTap: () => _openChatModal(name, message, avatar),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openChatModal(String name, String message, String avatar) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return _ChatConversationSheet(
          name: name,
          initialMessage: message,
          avatar: avatar,
        );
      },
    );
  }
}

class _ChatConversationSheet extends StatefulWidget {
  final String name;
  final String initialMessage;
  final String avatar;

  const _ChatConversationSheet({
    required this.name,
    required this.initialMessage,
    required this.avatar,
  });

  @override
  State<_ChatConversationSheet> createState() => _ChatConversationSheetState();
}

class _ChatConversationSheetState extends State<_ChatConversationSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _translatedText;
  bool _isTranslating = false;
  bool _isSending = false;
  String _targetLang = 'en';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTranslation() async {
    setState(() => _isTranslating = true);
    final fromLang = _targetLang == 'en' ? 'sw' : 'en';
    final result = await MessagingService.translate(
      text: widget.initialMessage,
      from: fromLang,
      to: _targetLang,
    );
    if (mounted) {
      setState(() {
        _isTranslating = false;
        _translatedText = result ?? 'Translation unavailable';
        _targetLang = _targetLang == 'en' ? 'sw' : 'en';
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    // 1. Filter obscenities / toxic content with PurgoMalum
    final cleaned = await MessagingService.filterProfanity(text);

    // 2. Dispatch real-time alert via ntfy.sh
    await MessagingService.sendNtfyAlert(
      topic: 'baterpoint-user-${widget.name}',
      title: 'Reply from Baterpoint Trader',
      body: cleaned,
      tags: ['speech_balloon', 'handshake'],
    );

    if (mounted) {
      setState(() => _isSending = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimaryColor,
          content: Text(
            cleaned != text
                ? 'Message sanitized & sent via ntfy.sh'
                : 'Message delivered via ntfy.sh',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final avatarUrl = widget.avatar.startsWith('http')
        ? widget.avatar
        : getDiceBearAvatar(widget.name);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
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
                        Icon(Icons.circle, color: Color(0xFF2E7D32), size: 9),
                        SizedBox(width: 4),
                        Text(
                          'Active on Baterpoint',
                          style: TextStyle(fontSize: 11, color: kTextLightColor),
                        ),
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
          const SizedBox(height: 16),
          // Received Message Bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialMessage,
                  style: const TextStyle(fontSize: 14, color: kTextColor, height: 1.4),
                ),
                if (_translatedText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kSecondaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.translate_rounded, color: kSecondaryColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _translatedText!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: kTextColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Translation Button powered by MyMemory API
          TextButton.icon(
            onPressed: _isTranslating ? null : _handleTranslation,
            icon: _isTranslating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.g_translate_rounded, size: 18),
            label: Text(
              _isTranslating
                  ? 'Translating…'
                  : 'Translate to ${_targetLang == 'en' ? 'English' : 'Swahili'} (MyMemory)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          // Reply input field with PurgoMalum moderation and ntfy.sh delivery
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type a reply to ${widget.name}…',
                    hintStyle: const TextStyle(fontSize: 13, color: kTextLightColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: kBorderColor),
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
                  onPressed: _isSending ? null : _sendReply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

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
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(name),
                        content: Text(message),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';


class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ChatService _chatService = ChatService();
  List<dynamic> _inboxItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    // Only show loading indicator on initial load, refresh indicator handles subsequent
    if (_inboxItems.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final items = await _chatService.getInbox();
      if (mounted) {
        setState(() {
          _inboxItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(String timestamp) {
    final time = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(time); // 5:30 PM
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(time); // Mon, Tue
    } else {
      return DateFormat.MMMd().format(time); // Oct 12
    }
  }

  void _startNewChat() {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Start New Chat'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              hintText: 'Enter user email',
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  final user = await _chatService.getUserByEmail(email);
                  if (user != null) {
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipientId: user['id'],
                            recipientEmail: user['email'],
                            recipientName: user['username'],
                            recipientAvatar: user['avatar_url'],
                          ),
                        ),
                      ).then((_) => _loadInbox());
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not found')),
                      );
                    }
                  }
                }
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInbox,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _inboxItems.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No messages yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startNewChat,
                            icon: const Icon(Icons.add),
                            label: const Text('Start a Conversation'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _inboxItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final item = _inboxItems[index];
                      final isUnread = item['unread_count'] > 0;
                      final avatarUrl = item['other_user_avatar'];

                      return ListTile(
                        tileColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: avatarUrl != null 
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
                              child: avatarUrl == null
                                  ? Text(
                                      item['other_user_username'][0].toUpperCase(),
                                      style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 20),
                                    )
                                  : null,
                            ),
                            if (isUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['other_user_username'],
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, 
                                fontSize: 16
                              ),
                            ),
                            Text(
                              _formatTime(item['last_message_time']),
                              style: TextStyle(
                                color: isUnread ? Colors.blue : Colors.grey.shade500, 
                                fontSize: 12,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['last_message'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isUnread ? Colors.black87 : Colors.grey.shade600,
                                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (item['unread_count'] > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${item['unread_count']}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                recipientId: item['other_user_id'],
                                recipientEmail: item['other_user_email'],
                                recipientName: item['other_user_username'],
                                recipientAvatar: item['other_user_avatar'],
                                tradeId: item['listing_id'],
                              ),
                            ),
                          ).then((_) => _loadInbox());
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message_outlined, color: Colors.white),
      ),
    );
  }
}

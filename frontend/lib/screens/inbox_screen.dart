import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/ui_constants.dart';
import '../constants/theme.dart';
import 'dart:ui';


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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Messages', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _inboxItems.length,
                    itemBuilder: (context, index) {
                      final item = _inboxItems[index];
                      final isUnread = item['unread_count'] > 0;
                      final avatarUrl = item['other_user_avatar'];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Hero(
                              tag: 'avatar_${item['other_user_id']}',
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                                    backgroundImage: avatarUrl != null 
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : null,
                                    child: avatarUrl == null
                                        ? Text(
                                            item['other_user_username'][0].toUpperCase(),
                                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 18),
                                          )
                                        : null,
                                  ),
                                  if (isUnread)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['other_user_username'],
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatTime(item['last_message_time']),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: isUnread ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.5),
                                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w500,
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
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: isUnread ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (item['unread_count'] > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${item['unread_count']}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
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
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: colorScheme.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }
}

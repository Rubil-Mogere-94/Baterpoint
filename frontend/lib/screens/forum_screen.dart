import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../constants/ui_constants.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ChatService _chatService = ChatService();
  String _selectedCategory = 'general';
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'general', 'label': 'General', 'icon': '💬'},
    {'id': 'tips', 'label': 'Trading Tips', 'icon': '💡'},
    {'id': 'requests', 'label': 'Trade Requests', 'icon': '🤝'},
    {'id': 'showcase', 'label': 'Showcase', 'icon': '✨'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectSocket();
  }

  void _connectSocket() {
    _chatService.connect(forumCategory: _selectedCategory);
    _chatService.onForumMessageReceived = (message) {
      if (mounted && (message.forumCategory == _selectedCategory || _selectedCategory == 'general')) {
        setState(() {
          _messages.insert(0, message);
        });
      }
    };
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await _chatService.getForumMessages(_selectedCategory);
      if (mounted) {
        setState(() {
          _messages = msgs.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    Vibrate.feedback(FeedbackType.light);
    _chatService.sendForumMessage(_selectedCategory, text);
    _messageController.clear();
  }

  @override
  void dispose() {
    _chatService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return HolographicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('Community Forum', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {},
            ),
          ],
        ),
      body: Column(
        children: [
          _buildCategoryBar(colorScheme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessageItem(_messages[index], colorScheme),
                      ),
          ),
          _buildInputArea(colorScheme),
        ],
      ),
    ));
  }

  Widget _buildCategoryBar(ColorScheme colorScheme) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];
          return GestureDetector(
            onTap: () {
              Vibrate.feedback(FeedbackType.selection);
              setState(() {
                _selectedCategory = cat['id']!;
                _loadMessages();
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? colorScheme.primary : Colors.white.withOpacity(0.2)),
                    boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                  ),
              child: Row(
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  message.sender[0].toUpperCase(),
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                message.sender,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message.message,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.9), height: 1.5, fontSize: 14),
          ),
          if (message.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(message.imageUrl!, fit: BoxFit.cover),
            ),
          ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.8),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Share something with the community...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No messages in this category yet.',
            style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to start a conversation!',
            style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

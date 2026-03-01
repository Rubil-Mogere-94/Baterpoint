import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final int? tradeId;
  final int? recipientId;
  final String? recipientEmail;
  final String? forumCategory;
  final String? recipientName;
  final String? recipientAvatar;

  const ChatScreen({
    super.key, 
    this.tradeId,
    this.recipientId,
    this.recipientEmail,
    this.forumCategory,
    this.recipientName,
    this.recipientAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  String? _typingUser;
  Timer? _typingTimer;
  bool _isSendingImage = false;
  bool _isForum = false;

  @override
  void initState() {
    super.initState();
    _isForum = widget.forumCategory != null;

    _chatService.onMessageReceived = (message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        if (!_isForum) _markMessagesAsRead();
      }
    };

    _chatService.onForumMessageReceived = (message) {
      if (mounted && _isForum) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    };
    
    _chatService.onTypingStatusChanged = (username, isTyping) {
      if (mounted) {
        setState(() {
          _typingUser = isTyping ? username : null;
        });
      }
    };

    _chatService.onMessagesRead = (messageIds) {
      if (mounted) {
        setState(() {
          for (var id in messageIds) {
            final index = _messages.indexWhere((m) => m.id == id);
            if (index != -1) {
              final old = _messages[index];
              _messages[index] = ChatMessage(
                id: old.id,
                sender: old.sender,
                message: old.message,
                imageUrl: old.imageUrl,
                isRead: true,
                timestamp: old.timestamp,
                tradeId: old.tradeId,
              );
            }
          }
        });
      }
    };

    if (_isForum) {
      _loadForumHistory();
      _chatService.connect(forumCategory: widget.forumCategory);
    } else {
      _chatService.connect(tradeId: widget.tradeId);
      _markMessagesAsRead();
    }
  }

  Future<void> _loadForumHistory() async {
    if (widget.forumCategory != null) {
      final history = await _chatService.getForumMessages(widget.forumCategory!);
      if (mounted) {
        setState(() {
          _messages.addAll(history);
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _markMessagesAsRead() {
    if (_isForum) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final unreadIds = _messages
        .where((m) => m.sender != auth.user?.username && !m.isRead && m.id != null)
        .map((m) => m.id!)
        .toList();
    
    if (unreadIds.isNotEmpty) {
      _chatService.markAsRead(unreadIds);
      setState(() {
        for (var id in unreadIds) {
          final index = _messages.indexWhere((m) => m.id == id);
          if (index != -1) {
            final old = _messages[index];
             _messages[index] = ChatMessage(
                id: old.id,
                sender: old.sender,
                message: old.message,
                imageUrl: old.imageUrl,
                isRead: true,
                timestamp: old.timestamp,
                tradeId: old.tradeId,
              );
          }
        }
      });
    }
  }

  void _onTextChanged(String value) {
    if (_isForum) return;
    if (_typingTimer?.isActive ?? false) _typingTimer?.cancel();
    
    _chatService.sendTypingStatus(true);
    
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.sendTypingStatus(false);
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _isSendingImage = true);
      try {
        final imageUrl = await _chatService.uploadImage(File(image.path));
        if (imageUrl != null) {
          _sendMessage("", imageUrl: imageUrl);
        }
      } finally {
        setState(() => _isSendingImage = false);
      }
    }
  }

  void _sendMessage(String text, {String? imageUrl}) {
    if (_isForum) {
      _chatService.sendForumMessage(widget.forumCategory!, text, imageUrl: imageUrl);
    } else {
      _chatService.sendMessage(
        text,
        tradeId: widget.tradeId,
        recipientId: widget.recipientId,
        recipientEmail: widget.recipientEmail,
        imageUrl: imageUrl,
      );
    }
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final currentDate = _messages[index].timestamp;
    final previousDate = _messages[index - 1].timestamp;
    return currentDate.year != previousDate.year ||
           currentDate.month != previousDate.month ||
           currentDate.day != previousDate.day;
  }

  @override
  void dispose() {
    _chatService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUsername = auth.user?.username;

    String appBarTitle = 'Chat';
    String appBarSubtitle = '';

    if (_isForum) {
      appBarTitle = 'Community Forum';
      appBarSubtitle = widget.forumCategory ?? 'General';
    } else if (widget.recipientName != null) {
      appBarTitle = widget.recipientName!;
      if (widget.tradeId != null) {
        appBarSubtitle = 'Discussing Trade #${widget.tradeId}';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (!_isForum && widget.recipientAvatar != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(widget.recipientAvatar!),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appBarTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                if (appBarSubtitle.isNotEmpty)
                  Text(appBarSubtitle, style: TextStyle(fontSize: 11, color: Colors.indigo.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg.sender == currentUsername;
                  final showDate = _shouldShowDateSeparator(index);
                  
                  return Column(
                    children: [
                      if (showDate)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                DateFormat.yMMMd().format(msg.timestamp),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ),
                      _ChatBubble(
                        message: msg.message,
                        sender: msg.sender,
                        timestamp: msg.timestamp,
                        imageUrl: msg.imageUrl,
                        isRead: msg.isRead,
                        isMe: isMe,
                        avatarUrl: !isMe && !_isForum ? widget.recipientAvatar : null,
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_typingUser != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.indigo.shade300),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_typingUser is typing...',
                      style: TextStyle(fontSize: 12, color: const Color(0xFF64748B), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF94A3B8), size: 28),
                        onPressed: _isSendingImage ? null : _pickImage,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          onChanged: _onTextChanged,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            isDense: true,
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _isSendingImage 
                      ? const Padding(padding: EdgeInsets.only(bottom: 8), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                      : Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              if (_messageController.text.trim().isNotEmpty) {
                                _sendMessage(_messageController.text.trim());
                                _messageController.clear();
                                if (!_isForum) _chatService.sendTypingStatus(false);
                              }
                            },
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
  }
}


class _ChatBubble extends StatelessWidget {
  final String message;
  final String sender;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isRead;
  final bool isMe;
  final String? avatarUrl;

  const _ChatBubble({
    required this.message,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
    required this.isRead,
    required this.isMe,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeString = DateFormat.jm().format(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 2),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
                    child: avatarUrl == null 
                        ? Text(sender[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isMe ? theme.colorScheme.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl!,
                              placeholder: (context, url) => Container(width: 200, height: 150, color: const Color(0xFFF8FAFC)),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isMe ? Colors.white : const Color(0xFF334155),
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 6, left: isMe ? 0 : 38, right: isMe ? 4 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeString,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: isRead ? Colors.indigo.shade400 : const Color(0xFFCBD5E1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

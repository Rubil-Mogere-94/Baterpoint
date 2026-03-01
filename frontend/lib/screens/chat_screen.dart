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
      // Simplified subtitle logic
      if (widget.tradeId != null) {
        appBarSubtitle = 'Trade #${widget.tradeId}';
      }
    } else if (widget.tradeId != null) {
      appBarTitle = 'Negotiation Chat';
      appBarSubtitle = 'Trade #${widget.tradeId}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // Slightly darker background for contrast
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (!_isForum && widget.recipientAvatar != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(widget.recipientAvatar!),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appBarTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                if (appBarSubtitle.isNotEmpty)
                  Text(appBarSubtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.green.shade700)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DateFormat.yMMMd().format(msg.timestamp),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
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
                      avatarUrl: !isMe && !_isForum ? widget.recipientAvatar : null, // Show avatar for 1:1 if available
                    ),
                  ],
                );
              },
            ),
          ),
          if (_typingUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_typingUser is typing...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Extra bottom padding for iOS home indicator
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add_photo_alternate_rounded, color: Colors.grey.shade600),
                      onPressed: _isSendingImage ? null : _pickImage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTextChanged,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          isDense: true,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isSendingImage 
                    ? const Padding(padding: EdgeInsets.only(bottom: 8, right: 8), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
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
                          icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
                    child: avatarUrl == null 
                        ? Text(sender[0].toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? theme.colorScheme.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl!,
                              placeholder: (context, url) => Container(width: 200, height: 150, color: Colors.grey.shade100),
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
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                              height: 1.3,
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
            padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 40, right: isMe ? 0 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeString,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 16,
                    color: isRead ? Colors.blue.shade600 : Colors.grey.shade400,
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

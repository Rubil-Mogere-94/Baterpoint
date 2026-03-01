import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final int tradeId;
  const ChatScreen({super.key, required this.tradeId});

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

  @override
  void initState() {
    super.initState();
    _chatService.onMessageReceived = (message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        _markMessagesAsRead();
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

    _chatService.connect(widget.tradeId);
    _markMessagesAsRead();
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
          _chatService.sendMessage(widget.tradeId, "", imageUrl: imageUrl);
        }
      } finally {
        setState(() => _isSendingImage = false);
      }
    }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Negotiation Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Trade #${widget.tradeId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.sender == currentUsername;
                
                return _ChatBubble(
                  message: msg.message,
                  sender: msg.sender,
                  timestamp: msg.timestamp,
                  imageUrl: msg.imageUrl,
                  isRead: msg.isRead,
                  isMe: isMe,
                );
              },
            ),
          ),
          if (_typingUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '$_typingUser is typing...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate_outlined, color: theme.colorScheme.primary),
                    onPressed: _isSendingImage ? null : _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSendingImage 
                    ? const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                    : Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                          onPressed: () {
                            if (_messageController.text.trim().isNotEmpty) {
                              _chatService.sendMessage(widget.tradeId, _messageController.text.trim());
                              _messageController.clear();
                              _chatService.sendTypingStatus(false);
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

  const _ChatBubble({
    required this.message,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
    required this.isRead,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(sender[0].toUpperCase(), style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          sender,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? theme.colorScheme.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
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
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl!,
                                  placeholder: (context, url) => Container(width: 200, height: 150, color: Colors.grey.shade200),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          if (message.isNotEmpty)
                            Text(
                              message,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: isRead ? Colors.blue.shade300 : Colors.grey.shade400,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

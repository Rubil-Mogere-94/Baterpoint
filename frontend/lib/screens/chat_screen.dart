// frontend/lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

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

  @override
  void initState() {
    super.initState();
    _chatService.onMessageReceived = (message) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    };
    _chatService.connect(widget.tradeId);
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

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat - Trade #${widget.tradeId}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(msg.message),
                  trailing: Text(
                    '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      _chatService.sendMessage(widget.tradeId, _messageController.text);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

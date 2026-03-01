// frontend/lib/models/chat_message.dart
class ChatMessage {
  final int? id;
  final String sender;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime timestamp;
  final int tradeId;

  ChatMessage({
    this.id,
    required this.sender,
    required this.message,
    this.imageUrl,
    this.isRead = false,
    required this.timestamp,
    required this.tradeId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: json['sender'],
      message: json['message'],
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      tradeId: json['trade_id'],
    );
  }
}

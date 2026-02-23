// frontend/lib/models/chat_message.dart
class ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final int tradeId;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.tradeId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      tradeId: json['trade_id'],
    );
  }
}

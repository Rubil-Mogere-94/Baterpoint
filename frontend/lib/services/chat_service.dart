// frontend/lib/services/chat_service.dart
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'dart:convert';
import '../constants.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

class ChatService {
  late io.Socket socket;
  final AuthService _authService = AuthService();
  Function(ChatMessage)? onMessageReceived;
  Function(ChatMessage)? onForumMessageReceived;
  Function(String)? onStatusMessage;
  Function(String, bool)? onTypingStatusChanged;
  Function(List<int>)? onMessagesRead;

  void connect({int? tradeId, String? forumCategory}) async {
    final token = await _authService.getToken();
    
    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to Socket.IO');
      socket.emit('authenticate', {'token': token});
    });

    socket.on('authenticated', (_) {
      print('Authenticated with Socket.IO');
      if (tradeId != null) {
        socket.emit('join_trade_chat', {'trade_id': tradeId});
      }
      if (forumCategory != null) {
        socket.emit('join_forum', {'category': forumCategory});
      }
    });

    socket.on('message', (data) {
      if (onMessageReceived != null) {
        onMessageReceived!(ChatMessage.fromJson(data));
      }
    });

    socket.on('forum_message', (data) {
      if (onForumMessageReceived != null) {
        // We reuse ChatMessage for forum messages for simplicity
        // But some fields might be different, let's adapt
        final msg = ChatMessage(
          id: data['id'],
          sender: data['sender'],
          message: data['message'],
          imageUrl: data['image_url'],
          isRead: true,
          timestamp: DateTime.parse(data['timestamp']),
          tradeId: null,
        );
        onForumMessageReceived!(msg);
      }
    });

    socket.on('typing', (data) {
      if (onTypingStatusChanged != null) {
        onTypingStatusChanged!(data['username'], data['is_typing']);
      }
    });

    socket.on('messages_read', (data) {
      if (onMessagesRead != null) {
        onMessagesRead!(List<int>.from(data['message_ids']));
      }
    });

    socket.on('status_message', (data) {
      if (onStatusMessage != null) {
        onStatusMessage!(data['message']);
      }
    });

    socket.onDisconnect((_) => print('Disconnected from Socket.IO'));
  }

  void sendMessage(String message, {int? tradeId, int? recipientId, String? recipientEmail, String? imageUrl}) {
    socket.emit('send_message', {
      'trade_id': tradeId,
      'recipient_id': recipientId,
      'recipient_email': recipientEmail,
      'message': message,
      'image_url': imageUrl,
    });
  }

  void sendForumMessage(String category, String message, {String? imageUrl}) {
    socket.emit('send_forum_message', {
      'category': category,
      'message': message,
      'image_url': imageUrl,
    });
  }

  Future<List<dynamic>> getInbox() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/chat/inbox'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<List<ChatMessage>> getForumMessages(String category) async {
    final response = await http.get(
      Uri.parse('$apiUrl/forum/messages?category=$category'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((m) => ChatMessage(
        id: m['id'],
        sender: m['sender_username'],
        message: m['message_content'],
        imageUrl: m['image_url'],
        isRead: true,
        timestamp: DateTime.parse(m['timestamp']),
        tradeId: null,
      )).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/users/by-email/$email'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  void sendTypingStatus(bool isTyping) {
    socket.emit('typing', {'is_typing': isTyping});
  }

  void markAsRead(List<int> messageIds) {
    socket.emit('mark_as_read', {'message_ids': messageIds});
  }

  Future<String?> uploadImage(File image) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/chat/upload'));
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    final response = await request.send();
    if (response.statusCode == 201) {
      final body = await response.stream.bytesToString();
      final data = json.decode(body);
      return data['image_url'];
    }
    return null;
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}

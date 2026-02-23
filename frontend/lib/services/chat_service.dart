// frontend/lib/services/chat_service.dart
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

class ChatService {
  late io.Socket socket;
  final AuthService _authService = AuthService();
  Function(ChatMessage)? onMessageReceived;
  Function(String)? onStatusMessage;

  void connect(int tradeId) async {
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
      socket.emit('join_trade_chat', {'trade_id': tradeId});
    });

    socket.on('message', (data) {
      if (onMessageReceived != null) {
        onMessageReceived!(ChatMessage.fromJson(data));
      }
    });

    socket.on('status_message', (data) {
      if (onStatusMessage != null) {
        onStatusMessage!(data['message']);
      }
    });

    socket.onDisconnect((_) => print('Disconnected from Socket.IO'));
  }

  void sendMessage(int tradeId, String message) {
    socket.emit('send_message', {
      'trade_id': tradeId,
      'message': message,
    });
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}

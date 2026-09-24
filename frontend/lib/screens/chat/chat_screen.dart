import 'package:flutter/material.dart';
import '../../constants.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          _buildChatTile(
            context,
            name: 'Alice',
            message: 'Hey, is the MacBook still available?',
            time: '2m ago',
            unread: 2,
          ),
          const Divider(),
          _buildChatTile(
            context,
            name: 'Bob',
            message: 'I can offer $150 for the guitar',
            time: '1h ago',
            unread: 0,
          ),
          const Divider(),
          _buildChatTile(
            context,
            name: 'Carol',
            message: 'Thanks for the trade!',
            time: '3h ago',
            unread: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context,
      {required String name,
      required String message,
      required String time,
      required int unread}) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(name[0]),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: kTextLightColor, fontSize: 13),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(color: kTextLightColor, fontSize: 12)),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
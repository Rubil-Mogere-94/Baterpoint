import 'package:flutter/material.dart';
import 'chat_screen.dart';

class CommunityForumScreen extends StatelessWidget {
  const CommunityForumScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {
      'name': 'General Discussion',
      'id': 'general',
      'icon': Icons.chat_outlined,
      'description': 'Talk about anything and everything.',
      'color': Colors.blue,
    },
    {
      'name': 'Trading Tips',
      'id': 'tips',
      'icon': Icons.lightbulb_outline,
      'description': 'Share and learn the best trading strategies.',
      'color': Colors.orange,
    },
    {
      'name': 'Item Authentication',
      'id': 'auth',
      'icon': Icons.verified_user_outlined,
      'description': 'Get help verifying the authenticity of items.',
      'color': Colors.green,
    },
    {
      'name': 'Success Stories',
      'id': 'success',
      'icon': Icons.star_border,
      'description': 'Share your best trades and experiences.',
      'color': Colors.purple,
    },
    {
      'name': 'Support & Feedback',
      'id': 'support',
      'icon': Icons.help_outline,
      'description': 'Need help? Have suggestions for Baterpoint?',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Community Forum', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (cat['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat['icon'] as IconData, color: cat['color'] as Color),
              ),
              title: Text(
                cat['name'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  cat['description'],
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      forumCategory: cat['id'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

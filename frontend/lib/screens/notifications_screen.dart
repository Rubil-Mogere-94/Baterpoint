import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final IconData icon;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.icon = Icons.notifications_rounded,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'New Offer Received',
      body: 'You received a new offer of \$150 for your "Vintage Camera".',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      icon: Icons.local_offer_rounded,
    ),
    NotificationModel(
      id: '2',
      title: 'Price Drop Alert',
      body: 'An item in your favorites "Sony WH-1000XM4" is now 10% cheaper!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      icon: Icons.trending_down_rounded,
    ),
    NotificationModel(
      id: '3',
      title: 'Order Completed',
      body: 'Your purchase of "Mechanical Keyboard" has been delivered.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      icon: Icons.check_circle_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var i = 0; i < _notifications.length; i++) {
                  // In a real app, this would call an API
                }
              });
            },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text('No notifications yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead 
                      ? theme.colorScheme.surfaceVariant 
                      : theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      notification.icon, 
                      color: notification.isRead ? Colors.grey : theme.colorScheme.primary
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to relevant screen if needed
                  },
                );
              },
            ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

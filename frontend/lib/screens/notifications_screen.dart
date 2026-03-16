import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final IconData icon;
  final Color accentColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.icon = Icons.notifications_rounded,
    this.accentColor = const Color(0xFF4F46E5),
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'New Offer Received',
        body: 'You received a new offer of \$150 for your "Vintage Camera".',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        icon: Icons.local_offer_rounded,
        accentColor: const Color(0xFF4F46E5),
      ),
      NotificationModel(
        id: '2',
        title: 'Price Drop Alert',
        body: '"Sony WH-1000XM4" in your favorites is now 10% cheaper!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
        icon: Icons.trending_down_rounded,
        accentColor: const Color(0xFF10B981),
      ),
      NotificationModel(
        id: '3',
        title: 'Order Completed',
        body: 'Your purchase of "Mechanical Keyboard" has been delivered.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        icon: Icons.check_circle_rounded,
        accentColor: const Color(0xFF10B981),
      ),
      NotificationModel(
        id: '4',
        title: 'Smart Match Found!',
        body: 'We found a high-compatibility match for your sneakers listing.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        icon: Icons.auto_awesome_rounded,
        accentColor: const Color(0xFFEC4899),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _notifications = _notifications
                      .map((n) => NotificationModel(
                            id: n.id,
                            title: n.title,
                            body: n.body,
                            timestamp: n.timestamp,
                            isRead: true,
                            icon: n.icon,
                            accentColor: n.accentColor,
                          ))
                      .toList();
                });
              },
              child: const Text(
                'Clear all',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: HolographicBackground(
        child: _notifications.isEmpty
            ? Center(
                child: ClipRRect(
                  borderRadius: AppRadius.roundedXXL,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      margin: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        borderRadius: AppRadius.roundedXXL,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'All caught up!',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No new notifications right now.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),

                  // Unread count badge
                  if (_notifications.any((n) => !n.isRead))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.15),
                                borderRadius: AppRadius.roundedPill,
                                border: Border.all(
                                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${_notifications.where((n) => !n.isRead).length} New',
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final notification = _notifications[index];
                        return _NotificationTile(
                          notification: notification,
                          isDark: isDark,
                          index: index,
                        );
                      },
                      childCount: _notifications.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final int index;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.index,
  });

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = notification.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.roundedXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(
                notification.isRead ? 0.03 : 0.07,
              ),
              borderRadius: AppRadius.roundedXL,
              border: Border.all(
                color: notification.isRead
                    ? (isDark ? Colors.white : Colors.black).withOpacity(0.08)
                    : accentColor.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(notification.isRead ? 0.08 : 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.isRead
                            ? Colors.grey
                            : accentColor,
                        size: 22,
                      ),
                    ),
                    if (!notification.isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.5),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w800,
                                color: notification.isRead ? Colors.grey : null,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: notification.isRead
                              ? Colors.grey
                              : (isDark ? Colors.white70 : Colors.black87),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideX(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: 100 + (index * 60)),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(delay: Duration(milliseconds: 100 + (index * 60)));
  }
}

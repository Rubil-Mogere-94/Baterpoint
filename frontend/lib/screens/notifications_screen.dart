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
        id: '4',
        title: 'Smart Match Found!',
        body: 'We found a high-compatibility match for your sneakers listing.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        icon: Icons.auto_awesome_rounded,
        accentColor: const Color(0xFFEC4899),
      ),
      NotificationModel(
        id: '2',
        title: 'Price Drop Alert',
        body: '"Sony WH-1000XM4" in your favorites is now 10% cheaper!',
        timestamp: DateTime.now().subtract(const Duration(hours: 22)),
        isRead: true,
        icon: Icons.trending_down_rounded,
        accentColor: const Color(0xFF10B981),
      ),
      NotificationModel(
        id: '3',
        title: 'Order Completed',
        body: 'Your purchase of "Mechanical Keyboard" has been delivered.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        icon: Icons.check_circle_rounded,
        accentColor: const Color(0xFF10B981),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final today = _notifications.where((n) => n.timestamp.isAfter(now.subtract(const Duration(days: 1)))).toList();
    final earlier = _notifications.where((n) => n.timestamp.isBefore(now.subtract(const Duration(days: 1)))).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: HolographicBackground(
        child: _notifications.isEmpty
            ? _buildEmptyState(theme, isDark)
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  if (today.isNotEmpty) ...[
                    _buildSectionHeader('Today'),
                    _buildNotificationList(today, isDark),
                  ],
                  if (earlier.isNotEmpty) ...[
                    _buildSectionHeader('Earlier'),
                    _buildNotificationList(earlier, isDark),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> list, bool isDark) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final notification = list[index];
          return _NotificationTile(
            notification: notification,
            isDark: isDark,
            index: index,
          );
        },
        childCount: list.length,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: AppSpacing.md),
          Text('Activity Feed is empty', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
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

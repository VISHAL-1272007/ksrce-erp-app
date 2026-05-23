import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';

class RealtimeNotificationsDashboard extends StatefulWidget {
  const RealtimeNotificationsDashboard({super.key});

  @override
  State<RealtimeNotificationsDashboard> createState() =>
      _RealtimeNotificationsDashboardState();
}

class _RealtimeNotificationsDashboardState
    extends State<RealtimeNotificationsDashboard> {
  late NotificationService _notificationService;
  String _selectedFilter = 'all';
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'assignment':
        return Colors.blue;
      case 'exam':
        return Colors.orange;
      case 'attendance':
        return Colors.red;
      case 'grade':
        return Colors.green;
      case 'event':
        return Colors.purple;
      case 'fee':
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment;
      case 'exam':
        return Icons.event_note;
      case 'attendance':
        return Icons.fact_check;
      case 'grade':
        return Icons.grade;
      case 'event':
        return Icons.celebration;
      case 'fee':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, ds, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notificationService.getUserNotificationsStream(ds.currentUserId ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var notifications = snapshot.data ?? [];

              // Apply filters
              if (_showOnlyUnread) {
                notifications =
                    notifications.where((n) => n['isRead'] != true).toList();
              }

              if (_selectedFilter != 'all') {
                notifications = notifications
                    .where((n) => n['type'] == _selectedFilter)
                    .toList();
              }

              final unreadCount =
                  (snapshot.data ?? []).where((n) => n['isRead'] != true).length;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    expandedHeight: 140,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.notifications_active,
                                      color: AppColors.primary, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Notifications',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark)),
                                      Text('${notifications.length} total',
                                          style: const TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Filter & Action Bar
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Filter buttons
                          _buildFilterButton('all', 'All', null),
                          _buildFilterButton('assignment', 'Assignments',
                              Icons.assignment),
                          _buildFilterButton(
                              'exam', 'Exams', Icons.event_note),
                          _buildFilterButton('grade', 'Grades', Icons.grade),
                          _buildFilterButton('attendance', 'Attendance',
                              Icons.fact_check),
                          _buildFilterButton('event', 'Events',
                              Icons.celebration),
                        ],
                      ),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(top: 8)),

                  // Unread toggle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CheckboxListTile(
                        title: const Text('Show unread only',
                            style: TextStyle(fontSize: 14)),
                        value: _showOnlyUnread,
                        onChanged: (value) {
                          setState(() => _showOnlyUnread = value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(top: 8)),

                  // Notifications list
                  if (notifications.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlyUnread
                                  ? 'No unread notifications'
                                  : 'No notifications',
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notif = notifications[index];
                          final isRead = notif['isRead'] == true;
                          final type = notif['type'] ?? 'alert';
                          final color = _getTypeColor(type);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Material(
                              color: isRead
                                  ? AppColors.surface
                                  : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () async {
                                  if (!isRead) {
                                    await _notificationService
                                        .markNotificationAsRead(
                                      ds.currentUserId ?? '',
                                      notif['notificationId'] ?? '',
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isRead
                                          ? AppColors.border
                                          : color.withValues(alpha: 0.3),
                                      width: isRead ? 1 : 2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Icon container
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getTypeIcon(type),
                                          color: color,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 8),
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    notif['title'] ??
                                                        'Notification',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: !isRead
                                                          ? FontWeight.bold
                                                          : FontWeight.w500,
                                                      color:
                                                          AppColors.textDark,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                        alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    type,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              notif['message'] ?? '',
                                              style: const TextStyle(
                                                color: AppColors.textLight,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatTime(
                                                      notif['timestamp'] ??
                                                          ''),
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                if (notif['sender'] !=
                                                    null) ...[
                                                  const SizedBox(width: 12),
                                                  Icon(Icons.person,
                                                      size: 12,
                                                      color:
                                                          Colors.grey[500]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'From: ${notif['sender']}',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.grey[500],
                                                        fontSize: 11,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      SizedBox(
                                        width: 40,
                                        child: Column(
                                          children: [
                                            if (!isRead)
                                              Tooltip(
                                                message: 'Mark as read',
                                                child: IconButton(
                                                  icon: const Icon(
                                                      Icons.done,
                                                      size: 18),
                                                  onPressed: () async {
                                                    await _notificationService
                                                        .markNotificationAsRead(
                                                      ds.currentUserId ?? '',
                                                      notif['notificationId'] ??
                                                          '',
                                                    );
                                                  },
                                                  color: color,
                                                ),
                                              ),
                                            Tooltip(
                                              message: 'Delete',
                                              child: IconButton(
                                                icon: const Icon(Icons.close,
                                                    size: 18),
                                                onPressed: () async {
                                                  await _notificationService
                                                      .deleteNotification(
                                                    ds.currentUserId ?? '',
                                                    notif['notificationId'] ??
                                                        '',
                                                  );
                                                },
                                                color: Colors.grey[500],
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
                          );
                        },
                        childCount: notifications.length,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(
      String value, String label, IconData? icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifications = [
    _Notif(
      title: 'New Disease Detected',
      body: 'Leaf Spot confirmed on Tree #A-14 (92% confidence). Immediate action recommended.',
      time: '2 min ago',
      type: 'alert',
      read: false,
    ),
    _Notif(
      title: 'Scan Complete',
      body: 'Your scan of Sector B is complete. 12 trees analyzed, 1 disease detected.',
      time: '1 hour ago',
      type: 'success',
      read: false,
    ),
    _Notif(
      title: 'Treatment Reminder',
      body: 'Apply copper fungicide follow-up on Tree #A-14 is due today.',
      time: '3 hours ago',
      type: 'reminder',
      read: true,
    ),
    _Notif(
      title: 'Drone Upload Ready',
      body: 'Your drone footage (Sector C) has been processed and results are available.',
      time: 'Yesterday',
      type: 'info',
      read: true,
    ),
    _Notif(
      title: 'Weekly Report',
      body: 'Your weekly CocoScan health report is ready. Overall: 87% healthy.',
      time: 'Yesterday',
      type: 'report',
      read: true,
    ),
    _Notif(
      title: 'System Update',
      body: 'AI model updated to v2.1 — improved accuracy for Bud Rot detection.',
      time: '2 days ago',
      type: 'system',
      read: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.read).length;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('Notifications'),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.confirmed,
                borderRadius: BorderRadius.circular(10)),
              child: Text('$unread', style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => setState(() => _notifications.forEach((n) => n.read = true)),
            child: const Text('Mark All Read',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.divider),
                const SizedBox(height: 16),
                const Text('No notifications', style: AppTextStyles.heading3),
              ]),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _NotifCard(
                notif: _notifications[i],
                onTap: () => setState(() => _notifications[i].read = true),
                onDismiss: () => setState(() => _notifications.removeAt(i)),
              ),
            ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifCard({required this.notif, required this.onTap, required this.onDismiss});

  IconData get _icon => switch (notif.type) {
    'alert'    => Icons.warning_amber_rounded,
    'success'  => Icons.check_circle_rounded,
    'reminder' => Icons.alarm_rounded,
    'info'     => Icons.airplanemode_active_rounded,
    'report'   => Icons.bar_chart_rounded,
    _          => Icons.system_update_rounded,
  };

  Color get _color => switch (notif.type) {
    'alert'    => AppColors.confirmed,
    'success'  => AppColors.healthy,
    'reminder' => AppColors.uncertain,
    'info'     => AppColors.secondary,
    'report'   => const Color(0xFF4527A0),
    _          => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(notif.title + notif.time),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.confirmed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.delete_outline_rounded, color: AppColors.confirmed),
    ),
    onDismissed: (_) => onDismiss(),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.read ? AppColors.cardBg : _color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: notif.read ? AppColors.divider : _color.withOpacity(0.2)),
          boxShadow: AppShadows.card,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13)),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(notif.title, style: AppTextStyles.heading3.copyWith(
                    fontSize: 14,
                    fontWeight: notif.read ? FontWeight.w500 : FontWeight.w700))),
                if (!notif.read)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(notif.body, style: AppTextStyles.body.copyWith(fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(notif.time, style: AppTextStyles.caption),
            ]),
          ),
        ]),
      ),
    ),
  );
}

class _Notif {
  final String title, body, time, type;
  bool read;
  _Notif({required this.title, required this.body, required this.time,
      required this.type, required this.read});
}

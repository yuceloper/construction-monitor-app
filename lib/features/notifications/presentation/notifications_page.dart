import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_header.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  List<NotificationItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _service.getNotifications();
      final cutoff = DateTime.now().subtract(const Duration(days: 15));
      final items = all
          .where((item) => !item.createdAt.toLocal().isBefore(cutoff))
          .where((item) => item.type == 'WORK_ITEM_UPDATED' || item.isDailyTask)
          .toList();
      if (!mounted) return;
      setState(() => _items = items);
    } on NotificationException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(NotificationItem item) async {
    if (!item.isRead) {
      try {
        await _service.markAsRead(item.id);
        if (mounted) {
          setState(() {
            _items = _items
                .map((current) => current.id == item.id ? current.copyWith(isRead: true) : current)
                .toList();
          });
        }
      } catch (_) {}
    }

    if (!mounted || item.referenceId == null) return;
    if (item.isDailyTask) {
      context.push('/daily-tasks/${item.referenceId}');
    } else if (item.type == 'WORK_ITEM_UPDATED') {
      context.push(
        '/process/Bildirimler/work/${item.referenceId}'
        '?title=${Uri.encodeQueryComponent(item.title)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/dashboard'),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bildirimler',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Text(
                    'Son 15 gün',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0066A6)));
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52, color: Colors.black38),
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        itemCount: _items.isEmpty ? 1 : _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          if (_items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 90),
              child: Column(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 70, color: Colors.black26),
                  SizedBox(height: 16),
                  Text(
                    'Son 15 günde bildirim bulunmuyor.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          final item = _items[index];
          return _NotificationCard(item: item, onTap: () => _open(item));
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDaily = item.isDailyTask;
    final color = isDaily ? const Color(0xFF11875D) : const Color(0xFF0066A6);
    final tint = isDaily ? const Color(0xFFF0FAF6) : const Color(0xFFF1F7FC);

    return Material(
      color: item.isRead ? const Color(0xFFF4F4F4) : tint,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDaily ? Icons.assignment_outlined : Icons.autorenew_rounded,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDaily ? 'Günlük İş Güncelleme' : 'Süreç Güncelleme',
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(item.message, style: const TextStyle(fontSize: 14, height: 1.35)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(item.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year}  $hour:$minute';
  }
}

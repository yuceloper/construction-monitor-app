import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      if (mounted) setState(() => _error = error.message);
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
    final unreadCount = _items.where((item) => !item.isRead).length;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/dashboard'),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Bildirimler',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEE2E3B),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
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
              ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        itemCount: _items.isEmpty ? 1 : _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (_items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 90),
              child: Center(
                child: Text(
                  'Son 15 günde bildirim bulunmuyor.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
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
    final accent = isDaily ? const Color(0xFF78B9F2) : const Color(0xFFFFDF79);
    final content = _NotificationContent.fromItem(item);

    return Material(
      color: const Color(0xFFE9E9E9),
      borderRadius: BorderRadius.circular(21),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 30, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              content.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.05,
                                fontWeight: isDaily ? FontWeight.w500 : FontWeight.w800,
                                color: isDaily ? Colors.black54 : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(item.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (content.detail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          content.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.05,
                            fontWeight: isDaily ? FontWeight.w400 : FontWeight.w700,
                            color: isDaily ? Colors.black54 : const Color(0xFF0066A6),
                          ),
                        ),
                      ],
                      if (isDaily && (content.block.isNotEmpty || content.person.isNotEmpty)) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                content.block,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.05,
                                  color: Color(0xFF0066A6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (content.person.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                content.person,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.05,
                                  color: Color(0xFF0066A6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
    return '$day.$month.${date.year}';
  }
}

class _NotificationContent {
  final String title;
  final String detail;
  final String block;
  final String person;

  const _NotificationContent({
    required this.title,
    required this.detail,
    required this.block,
    required this.person,
  });

  factory _NotificationContent.fromItem(NotificationItem item) {
    if (!item.isDailyTask) {
      return _NotificationContent(
        title: item.title,
        detail: item.message,
        block: '',
        person: '',
      );
    }

    final lines = item.message
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    var detail = lines.isNotEmpty ? lines.first : '';
    var block = item.projectName ?? '';
    var person = '';

    for (final line in lines.skip(1)) {
      if (line.toLowerCase().startsWith('blok:')) {
        final value = line.substring(line.indexOf(':') + 1).trim();
        block = value.isEmpty ? block : 'Evler - $value';
      } else if (line.toLowerCase().startsWith('kişi:') || line.toLowerCase().startsWith('kisi:')) {
        person = line.substring(line.indexOf(':') + 1).trim();
      } else if (!line.toLowerCase().startsWith('tarih:') && detail.isEmpty) {
        detail = line;
      }
    }

    if (block.isNotEmpty && !block.contains(' - ')) {
      block = 'Evler - $block';
    }

    return _NotificationContent(
      title: item.title,
      detail: detail,
      block: block,
      person: person,
    );
  }
}

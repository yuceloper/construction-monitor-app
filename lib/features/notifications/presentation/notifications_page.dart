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
  bool _markingAll = false;
  String? _error;
  _NotificationFilter _filter = _NotificationFilter.all;

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
      final items = await _service.getNotifications();
      if (!mounted) return;
      setState(() => _items = items);
    } on NotificationException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<NotificationItem> get _filteredItems {
    return switch (_filter) {
      _NotificationFilter.all => _items,
      _NotificationFilter.unread => _items.where((item) => !item.isRead).toList(),
      _NotificationFilter.workItem => _items.where((item) => item.isWorkItem).toList(),
      _NotificationFilter.dailyTask => _items.where((item) => item.isDailyTask).toList(),
    };
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _items.every((item) => item.isRead)) return;
    setState(() => _markingAll = true);
    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      setState(() => _items = _items.map((item) => item.copyWith(isRead: true)).toList());
    } on NotificationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(NotificationItem item) async {
    if (!item.isRead) {
      try {
        await _service.markAsRead(item.id);
        if (mounted) {
          setState(() {
            _items = _items.map((current) => current.id == item.id ? current.copyWith(isRead: true) : current).toList();
          });
        }
      } catch (_) {
        // Navigation should still work if the read-state update temporarily fails.
      }
    }
    if (!mounted || item.referenceId == null) return;

    if (item.isDailyTask) {
      context.push('/daily-tasks/${item.referenceId}');
      return;
    }
    if (item.isWorkItem) {
      final title = Uri.encodeQueryComponent(item.title);
      context.push('/process/Bildirimler/work/${item.referenceId}?title=$title');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F7FA),
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            _topBar(),
            _filters(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    final unreadCount = _items.where((item) => !item.isRead).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/dashboard'),
            borderRadius: BorderRadius.circular(24),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Bildirimler', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markingAll ? null : _markAllRead,
              icon: _markingAll
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.done_all_rounded, size: 19),
              label: const Text('Tümünü oku'),
            ),
        ],
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          _chip('Tümü', _NotificationFilter.all),
          _chip('Okunmadı', _NotificationFilter.unread),
          _chip('Alt Kalem', _NotificationFilter.workItem),
          _chip('Günlük İş', _NotificationFilter.dailyTask),
        ],
      ),
    );
  }

  Widget _chip(String label, _NotificationFilter value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        selectedColor: const Color(0xFF2463B6),
        backgroundColor: const Color(0xFFE9EDF3),
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF26354A),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2463B6)));
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
              FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    final items = _filteredItems;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          if (items.isEmpty)
            _emptyState()
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationCard(item: item, onTap: () => _open(item)),
                )),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final message = switch (_filter) {
      _NotificationFilter.all => 'Henüz bildirim bulunmuyor.',
      _NotificationFilter.unread => 'Okunmamış bildirimin yok.',
      _NotificationFilter.workItem => 'Alt kalem bildirimi bulunmuyor.',
      _NotificationFilter.dailyTask => 'Günlük iş bildirimi bulunmuyor.',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          const Icon(Icons.notifications_none_rounded, size: 70, color: Colors.black26),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
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
    final style = _styleFor(item);
    return Material(
      color: item.isRead ? Colors.white : style.tint,
      borderRadius: BorderRadius.circular(18),
      elevation: item.isRead ? 1 : 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: style.iconBackground, borderRadius: BorderRadius.circular(15)),
                child: Icon(style.icon, color: style.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: style.badgeBackground, borderRadius: BorderRadius.circular(10)),
                          child: Text(style.badge, style: TextStyle(color: style.color, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        Text(_formatTime(item.createdAt), style: const TextStyle(color: Color(0xFF718096), fontSize: 12)),
                        if (!item.isRead) ...[
                          const SizedBox(width: 8),
                          const CircleAvatar(radius: 4, backgroundColor: Color(0xFF1677FF)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF121826))),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.projectName == null || item.projectName!.isEmpty
                            ? item.message
                            : '${item.projectName} › ${item.message}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF667085)),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.referenceId != null) ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Icon(Icons.chevron_right_rounded, color: Colors.black38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static _NotificationStyle _styleFor(NotificationItem item) {
    if (item.type == 'WORK_ITEM_WARNING' || item.type == 'WORK_ITEM_STALE') {
      return const _NotificationStyle(
        badge: 'Uyarı',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFD94841),
        iconBackground: Color(0xFFFFE8E6),
        badgeBackground: Color(0xFFFFE4E1),
        tint: Color(0xFFFFFAF9),
      );
    }
    if (item.isDailyTask) {
      return const _NotificationStyle(
        badge: 'Günlük İş',
        icon: Icons.assignment_outlined,
        color: Color(0xFF11875D),
        iconBackground: Color(0xFFE3F5ED),
        badgeBackground: Color(0xFFE1F4EB),
        tint: Color(0xFFF8FFFB),
      );
    }
    if (item.type == 'WORK_ITEM_FREQUENT_UPDATE') {
      return const _NotificationStyle(
        badge: 'Güncelleme',
        icon: Icons.bar_chart_rounded,
        color: Color(0xFF6D43C5),
        iconBackground: Color(0xFFEDE5FF),
        badgeBackground: Color(0xFFE9E1FF),
        tint: Color(0xFFFCFAFF),
      );
    }
    if (item.isWorkItem) {
      return const _NotificationStyle(
        badge: 'Güncelleme',
        icon: Icons.edit_outlined,
        color: Color(0xFF2463B6),
        iconBackground: Color(0xFFE4EEFB),
        badgeBackground: Color(0xFFE1ECFA),
        tint: Color(0xFFF8FBFF),
      );
    }
    return const _NotificationStyle(
      badge: 'Bildirim',
      icon: Icons.notifications_none_rounded,
      color: Color(0xFF596579),
      iconBackground: Color(0xFFEDF0F4),
      badgeBackground: Color(0xFFE9EDF2),
      tint: Color(0xFFFAFBFC),
    );
  }

  static String _formatTime(DateTime value) {
    final date = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    if (difference == 0) return 'Bugün $hour:$minute';
    if (difference == 1) return 'Dün $hour:$minute';
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _NotificationStyle {
  final String badge;
  final IconData icon;
  final Color color;
  final Color iconBackground;
  final Color badgeBackground;
  final Color tint;

  const _NotificationStyle({
    required this.badge,
    required this.icon,
    required this.color,
    required this.iconBackground,
    required this.badgeBackground,
    required this.tint,
  });
}

enum _NotificationFilter { all, unread, workItem, dailyTask }

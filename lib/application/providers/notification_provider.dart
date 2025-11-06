import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sparix/data/repositories/notification_repository.dart';
import 'package:sparix/data/models/notification.dart' as model;

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _store;

  List<model.Notification> _items = [];
  List<model.Notification> get items => _items;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<List<model.Notification>>? _sub;

  NotificationProvider({NotificationRepository? store}) : _store = store ?? NotificationRepository();

  Future<void> start() async {
    await _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _store.getNotifications().listen((list) {
      _items = list;
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> markRead(String id, {bool value = true}) async {
    await _store.markAsRead(id, value: value);
  }

  Future<void> markUnread(String id, {bool value = false}) async {
    await _store.markAsUnread(id, value: value);
  }

  int get unreadCount => _items.where((n) => !n.read).length;
  List<model.Notification> get unreadItems => _items.where((n) => !n.read).toList(growable: false);
  bool get hasUnread => unreadCount > 0;

  Future<void> remove(String id) async {
    await _store.deleteNotification(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

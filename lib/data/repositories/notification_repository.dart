import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparix/data/models/notification.dart' as model;

class NotificationRepository {
  final CollectionReference _notifRef = FirebaseFirestore.instance.collection('notification');

  Stream<List<model.Notification>> getNotifications() {
    return _notifRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return model.Notification.fromJson(
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Future<void> markAsRead(String notifId, {required bool value}) async {
    await _notifRef.doc(notifId).update({'read': value});
  }

  Future<void> markAsUnread(String notifId, {required bool value}) async {
    await _notifRef.doc(notifId).update({'read': value});
  }

  Future<void> deleteNotification(String notifId) async {
    await _notifRef.doc(notifId).delete();
  }
}

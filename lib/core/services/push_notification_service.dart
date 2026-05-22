import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  PushNotificationService(this._firestore, this._messaging);

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Future<void> registerDeviceForUser({required String userId}) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'notificationsEnabled': true,
      }, SetOptions(merge: true));
    }

    _messaging.onTokenRefresh.listen((updatedToken) async {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': updatedToken,
        'notificationsEnabled': true,
      }, SetOptions(merge: true));
    });
  }
}

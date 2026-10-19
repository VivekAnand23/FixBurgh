import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(
    ref.watch(sharedPreferencesProvider),
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
  ),
);

/// Push tokens and permission (BRD FR-NTF-01, 02). Each device keeps one
/// document at `users/{uid}/devices/{deviceId}` holding its FCM token.
class PushService {
  PushService(this._prefs, {required this.messaging, required this.firestore});

  static const _deviceKey = 'push.deviceId';
  static const _askedKey = 'push.rationaleShown';

  final SharedPreferences _prefs;
  final FirebaseMessaging messaging;
  final FirebaseFirestore firestore;
  StreamSubscription<String>? _refresh;

  /// Stable per install, so one person's phones don't overwrite each other.
  String get deviceId {
    var id = _prefs.getString(_deviceKey);
    if (id == null) {
      id = const Uuid().v4();
      unawaited(_prefs.setString(_deviceKey, id));
    }
    return id;
  }

  /// Whether the "get updates" explanation was already shown.
  bool get rationaleShown => _prefs.getBool(_askedKey) ?? false;

  Future<void> markRationaleShown() => _prefs.setBool(_askedKey, true);

  Future<bool> get isAllowed async {
    final s = await messaging.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Shows the system prompt. True when notifications are allowed.
  Future<bool> requestPermission() async {
    final s = await messaging.requestPermission();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Saves this device's token for [uid] and keeps it current.
  /// On iOS this needs an APNs key in Firebase; without one there is no
  /// token and this quietly does nothing.
  Future<void> register(String uid) async {
    if (!await isAllowed) {
      debugPrint('Push: notifications not allowed');
      return;
    }
    String? token;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await messaging.getAPNSToken() == null) {
        return;
      }
      token = await messaging.getToken();
    } on Object catch (e) {
      debugPrint('Push: no token ($e)');
      return;
    }
    if (token == null) return;
    await _save(uid, token);
    debugPrint('Push: registered this device');
    await _refresh?.cancel();
    _refresh = messaging.onTokenRefresh.listen((t) => _save(uid, t));
  }

  Future<void> _save(String uid, String token) => _device(uid).set({
    'token': token,
    'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Stops notifications to this device for [uid], e.g. before signing out.
  Future<void> unregister(String uid) async {
    await _refresh?.cancel();
    _refresh = null;
    try {
      await _device(uid).delete();
    } on Object {
      // Offline: the server drops the token when it stops working.
    }
  }

  DocumentReference<Map<String, dynamic>> _device(String uid) => firestore
      .collection('users')
      .doc(uid)
      .collection('devices')
      .doc(deviceId);
}

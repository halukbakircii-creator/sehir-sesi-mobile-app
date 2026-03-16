// lib/services/notification_service.dart
// Firebase Cloud Messaging — Bildirim servisi

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'supabase_service.dart';

// Arka planda gelen mesajları işle (top-level fonksiyon olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Arka plan bildirimi: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static const _storage = FlutterSecureStorage();

  static Future<void> initialize() async {
    // iOS izin iste
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Bildirim izni reddedildi');
      return;
    }

    // Arka plan handler kaydet
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Ön planda gelen bildirimleri işle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Ön planda bildirim: ${message.notification?.title}');
      // TODO: in-app notification göster (overlay/snackbar)
    });

    // Bildirime tıklanınca
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Bildirime tıklandı: ${message.data}');
      // TODO: ilgili ekrana yönlendir
    });

    // FCM token al ve Supabase'e kaydet
    await _saveTokenToSupabase();

    // Token yenilenince güncelle
    _messaging.onTokenRefresh.listen((newToken) async {
      await _storage.write(key: 'fcm_token', value: newToken);
      await _updateTokenInSupabase(newToken);
    });
  }

  static Future<void> _saveTokenToSupabase() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _storage.write(key: 'fcm_token', value: token);
      await _updateTokenInSupabase(token);
    } catch (e) {
      debugPrint('FCM token kaydedilemedi: $e');
    }
  }

  static Future<void> _updateTokenInSupabase(String token) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('users').update({
        'fcm_token': token,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('auth_id', user.id);
    } catch (e) {
      debugPrint('Supabase token güncellenemedi: $e');
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'fcm_token');
  }

  /// Belirli bir konuya abone ol (örn: "istanbul_feedbacks")
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

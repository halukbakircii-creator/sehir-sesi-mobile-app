// Bildirim servisi - şimdilik devre dışı
class NotificationService {
  static Future<void> initialize() async {}
  static Future<String?> getToken() async => null;
  static Future<void> subscribeToTopic(String topic) async {}
  static Future<void> unsubscribeFromTopic(String topic) async {}
}

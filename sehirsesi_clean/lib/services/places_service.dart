// lib/services/places_service.dart
// ŞehirSesi — Mekan Veri Katmanı (Supabase)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place_models.dart';

final _db = Supabase.instance.client;

class PlacesService {
  // ── MEKAN SORGULARI ───────────────────────────────────────────

  /// Mahalledeki tüm mekanlar
  Future<List<Place>> getNeighborhoodPlaces({
    required String province,
    required String district,
    required String neighborhood,
    List<PlaceCategoryType>? categories,
    int limit = 50,
  }) async {
    var query = _db
        .from('places')
        .select('''
          id, name, neighborhood, district, province,
          category, latitude, longitude, address, description,
          photo_url, avg_rating, review_count, monthly_visits,
          is_tourist_spot, is_verified, opening_hours, created_at
        ''')
        .eq('province', province)
        .eq('district', district)
        .eq('neighborhood', neighborhood)
        .eq('is_active', true)
        .order('avg_rating', ascending: false)
        .limit(limit);

    final data = await query;
    var places = (data as List).map((d) => Place.fromJson(d)).toList();

    if (categories != null && categories.isNotEmpty) {
      final names = categories.map((c) => c.name).toSet();
      places = places.where((p) => names.contains(p.category.name)).toList();
    }

    return places;
  }

  /// Şehir genelinde en popüler mekanlar
  Future<List<Place>> getTopPlaces({
    required String province,
    int limit = 20,
    PlaceCategoryType? category,
  }) async {
    var query = _db
        .from('places')
        .select('id, name, neighborhood, district, province, category, latitude, longitude, photo_url, avg_rating, review_count, monthly_visits, is_tourist_spot, is_verified, created_at')
        .eq('province', province)
        .eq('is_active', true)
        .gte('avg_rating', 4.0)
        .order('monthly_visits', ascending: false)
        .limit(limit);

    final data = await query;
    var places = (data as List).map((d) => Place.fromJson(d)).toList();

    if (category != null) {
      places = places.where((p) => p.category == category).toList();
    }

    return places;
  }

  /// Harita için mekan pinleri (hafif veri)
  Future<List<Map<String, dynamic>>> getPlacePins({
    required String province,
    required String district,
    List<PlaceCategoryType>? categories,
  }) async {
    final data = await _db
        .from('places')
        .select('id, name, category, latitude, longitude, avg_rating, is_tourist_spot')
        .eq('province', province)
        .eq('district', district)
        .eq('is_active', true);

    var pins = List<Map<String, dynamic>>.from(data);

    if (categories != null && categories.isNotEmpty) {
      final names = categories.map((c) => c.name).toSet();
      pins = pins.where((p) => names.contains(p['category'])).toList();
    }

    return pins;
  }

  // ── SKOR GEÇMİŞİ ─────────────────────────────────────────────

  /// Mahallenin son 90 günlük skor geçmişi
  Future<List<ScoreHistoryPoint>> getScoreHistory({
    required String province,
    required String district,
    required String neighborhood,
    int days = 90,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    final data = await _db
        .from('score_history')
        .select('recorded_at, overall_score, review_count')
        .eq('province', province)
        .eq('district', district)
        .eq('neighborhood', neighborhood)
        .gte('recorded_at', since)
        .order('recorded_at');

    return (data as List).map((d) => ScoreHistoryPoint.fromJson(d)).toList();
  }

  // ── FAVORİLER ─────────────────────────────────────────────────

  Future<void> addFavorite({
    required String userId,
    required String neighborhood,
    required String district,
    required String province,
    String? placeId,
  }) async {
    await _db.from('favorites').upsert({
      'user_id':     userId,
      'neighborhood': neighborhood,
      'district':    district,
      'province':    province,
      'place_id':    placeId,
    });
  }

  Future<void> removeFavorite({
    required String userId,
    required String neighborhood,
    String? placeId,
  }) async {
    var query = _db.from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('neighborhood', neighborhood);

    if (placeId != null) {
      // place_id filtresi - Supabase chain
      await _db.from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('place_id', placeId);
      return;
    }

    await query;
  }

  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    final data = await _db
        .from('favorites')
        .select('*, neighborhood_scores(overall_score, total_feedbacks)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<bool> isFavorite({
    required String userId,
    required String neighborhood,
  }) async {
    final data = await _db
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('neighborhood', neighborhood)
        .maybeSingle();

    return data != null;
  }

  // ── İTİNERARY / ROTA KAYDETME ─────────────────────────────────

  Future<String> saveItinerary({
    required String userId,
    required String name,
    required String neighborhood,
    required String province,
    required List<Map<String, dynamic>> stops,
    String? aiSummary,
  }) async {
    final result = await _db.from('itineraries').insert({
      'user_id':    userId,
      'name':       name,
      'neighborhood': neighborhood,
      'province':   province,
      'stops':      stops,
      'ai_summary': aiSummary,
    }).select('id').single();

    return result['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getUserItineraries(String userId) async {
    final data = await _db
        .from('itineraries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── MODERASYOn KUYRUĞU (admin) ────────────────────────────────

  Future<List<ModerationItem>> getModerationQueue({
    String province = 'İstanbul',
    int limit = 30,
  }) async {
    final data = await _db
        .from('moderation_queue')
        .select('''
          id, review_id, content, neighborhood, ai_reason,
          spam_score, status, created_at
        ''')
        .eq('province', province)
        .eq('status', 'pending')
        .order('spam_score', ascending: false)
        .limit(limit);

    return (data as List).map((d) => ModerationItem.fromJson(d)).toList();
  }

  Future<void> resolveModeration({
    required String moderationId,
    required String reviewId,
    required ModerationStatus decision,
    String? adminNote,
  }) async {
    await _db.from('moderation_queue').update({
      'status':     decision.name,
      'admin_note': adminNote,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', moderationId);

    // Eğer reddedildiyse yorumu gizle
    if (decision == ModerationStatus.rejected) {
      await _db.from('feedbacks')
          .update({'is_hidden': true})
          .eq('id', reviewId);
    }
  }

  // ── ARAMA ─────────────────────────────────────────────────────

  /// Mahalle veya mekan adına göre tam metin arama
  Future<List<Map<String, dynamic>>> search({
    required String query,
    required String province,
    int limit = 15,
  }) async {
    if (query.length < 2) return [];

    // Mekan araması
    final places = await _db
        .from('places')
        .select('id, name, neighborhood, district, category, avg_rating')
        .eq('province', province)
        .ilike('name', '%$query%')
        .limit(limit ~/ 2);

    // Mahalle araması
    final neighborhoods = await _db
        .from('neighborhood_scores')
        .select('neighborhood, district, overall_score, total_feedbacks')
        .eq('province', province)
        .ilike('neighborhood', '%$query%')
        .limit(limit ~/ 2);

    return [
      ...(places as List).map((p) => {...p, 'result_type': 'place'}),
      ...(neighborhoods as List).map((n) => {...n, 'result_type': 'neighborhood'}),
    ];
  }
}

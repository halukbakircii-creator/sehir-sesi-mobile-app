// lib/services/route_service.dart
// ŞehirSesi — Rota Öneri Motoru
//
// Kullanıcı rota tipi seçer → mekanları alır → en iyi durağı sıralar
// → AI ile kısa özet oluşturur → RecommendedRoute döner

import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/place_models.dart';
import 'places_service.dart';

class RouteService {
  final PlacesService _places;
  final Dio _dio;

  static const String _anthropicUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  RouteService({PlacesService? placesService, Dio? dio})
      : _places = placesService ?? PlacesService(),
        _dio = dio ??
            Dio(BaseOptions(headers: {
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            }));

  /// Ana metot: verilen mahalle + rota tipi için rota oluştur
  Future<RecommendedRoute> buildRoute({
    required String neighborhood,
    required String district,
    required String province,
    required RouteType type,
    LatLng? startingPoint,
  }) async {
    // 1. Mahalledeki mekanları çek
    final allPlaces = await _places.getNeighborhoodPlaces(
      province:     province,
      district:     district,
      neighborhood: neighborhood,
    );

    // 2. Rota tipine uygun kategorileri filtrele
    final preferred = type.preferredCategories;
    final filtered  = allPlaces.where((p) => preferred.contains(p.category)).toList();

    // Yeterince mekan yoksa tüm mekanları kullan
    final candidates = filtered.length >= 3 ? filtered : allPlaces;

    // 3. Durağı sırala (rating + tourist spot önceliği)
    candidates.sort((a, b) {
      final scoreA = _candidateScore(a);
      final scoreB = _candidateScore(b);
      return scoreB.compareTo(scoreA);
    });

    // 4. Rota süresine göre durak sayısını belirle
    final maxDuration = type.estimatedDuration;
    final stops = _buildStops(candidates, maxDuration, startingPoint, type);

    // 5. Toplam mesafe hesapla
    double totalKm = 0;
    for (int i = 0; i < stops.length - 1; i++) {
      final a = LatLng(stops[i].place.latitude, stops[i].place.longitude);
      final b = LatLng(stops[i + 1].place.latitude, stops[i + 1].place.longitude);
      totalKm += a.distanceTo(b);
    }

    // 6. AI özeti oluştur
    final summary = await _generateRouteSummary(stops, type, neighborhood);

    return RecommendedRoute(
      id:              '${neighborhood}_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      name:            '$neighborhood — ${type.label}',
      type:            type,
      neighborhood:    neighborhood,
      stops:           stops,
      totalDuration:   maxDuration,
      totalDistanceKm: totalKm,
      aiSummary:       summary,
      scoreFit:        _calcFit(stops),
    );
  }

  // ── YARDIMCILAR ───────────────────────────────────────────────

  double _candidateScore(Place p) {
    double s = (p.rating ?? 3.0) * 20;         // 0-100
    if (p.isTouristSpot) s += 15;
    if (p.isVerified)    s += 10;
    if (p.monthlyVisits > 500) s += 5;
    return s;
  }

  List<RouteStop> _buildStops(
    List<Place> candidates,
    Duration maxDuration,
    LatLng? start,
    RouteType type,
  ) {
    final List<RouteStop> stops = [];
    Duration remaining = maxDuration;
    Place? lastPlace;

    for (final place in candidates) {
      if (remaining.inMinutes <= 0) break;

      // Her durak için önerilen süre (kategori bazlı)
      final time = _suggestedTimeAt(place.category, type);
      if (remaining < time) break;

      // Bir önceki duraktan çok uzaksa atla (>1.5km)
      if (lastPlace != null) {
        final from = LatLng(lastPlace.latitude, lastPlace.longitude);
        final to   = LatLng(place.latitude, place.longitude);
        if (from.distanceTo(to) > 1.5) continue;
      }

      stops.add(RouteStop(
        place:        place,
        orderIndex:   stops.length,
        suggestedTime: time,
        tip:          _tipFor(place),
      ));

      remaining -= time;
      lastPlace  = place;

      // Makul üst sınır
      if (stops.length >= 6) break;
    }

    return stops;
  }

  Duration _suggestedTimeAt(PlaceCategoryType cat, RouteType type) {
    // Müze/tarihi yer daha uzun; kafe/park daha kısa
    switch (cat) {
      case PlaceCategoryType.museum:
      case PlaceCategoryType.monument:
        return const Duration(minutes: 45);
      case PlaceCategoryType.restaurant:
        return const Duration(minutes: 60);
      case PlaceCategoryType.cafe:
        return type == RouteType.coffeeAndWalk
            ? const Duration(minutes: 40)
            : const Duration(minutes: 20);
      case PlaceCategoryType.park:
      case PlaceCategoryType.nature:
        return const Duration(minutes: 30);
      default:
        return const Duration(minutes: 25);
    }
  }

  String? _tipFor(Place place) {
    switch (place.category) {
      case PlaceCategoryType.museum:     return 'Sabah erken gelin, kalabalıktan önce gezip çıkın.';
      case PlaceCategoryType.cafe:       return 'Pencere kenarı masalar çok tercih edilir, rezervasyon öneririz.';
      case PlaceCategoryType.park:       return 'Akşamüstü gün batımı için harika bir nokta.';
      case PlaceCategoryType.restaurant: return 'Yerel ustalara sormayı unutmayın; menü dışı lezzetler var.';
      case PlaceCategoryType.bar:        return 'Hafta içi çok daha sakin ve orijinal bir atmosfer sunar.';
      default:                           return null;
    }
  }

  double _calcFit(List<RouteStop> stops) {
    if (stops.isEmpty) return 0;
    final avg = stops
        .map((s) => (s.place.rating ?? 3.0) * 20)
        .reduce((a, b) => a + b) / stops.length;
    return avg.clamp(0.0, 100.0);
  }

  Future<String> _generateRouteSummary(
    List<RouteStop> stops,
    RouteType type,
    String neighborhood,
  ) async {
    if (stops.isEmpty) return 'Bu mahallede rota oluşturulamadı.';
    if (_apiKey.isEmpty) return _fallbackSummary(stops, type, neighborhood);

    try {
      final stopList = stops
          .map((s) => '${s.orderIndex + 1}. ${s.place.name} (${s.place.category.label})')
          .join('\n');

      final response = await _dio.post(_anthropicUrl, data: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 300,
        'system': 'Sen bir şehir rehberisin. Kısa, samimi ve heyecan verici Türkçe özet yaz.',
        'messages': [{
          'role': 'user',
          'content': '''
Mahalle: $neighborhood
Rota tipi: ${type.label}
Tahmini süre: ${type.estimatedDuration.inMinutes} dakika

Duraklar:
$stopList

Bu rota için 2-3 cümlelik heyecan verici bir özet yaz. Kullanıcıyı bu rotayı yapmaya ikna et.
''',
        }],
      }));

      return response.data['content'][0]['text'] as String;
    } catch (_) {
      return _fallbackSummary(stops, type, neighborhood);
    }
  }

  String _fallbackSummary(
    List<RouteStop> stops,
    RouteType type,
    String neighborhood,
  ) {
    final names = stops.take(3).map((s) => s.place.name).join(', ');
    return '$neighborhood\'de ${type.estimatedDuration.inMinutes} dakikalık '
        '${type.label} rotanız hazır. $names ve daha fazlası sizi bekliyor!';
  }
}

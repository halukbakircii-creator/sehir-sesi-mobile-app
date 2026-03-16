// lib/models/place_models.dart
// ŞehirSes — Mekan, Filtre ve Rota Modelleri

import 'package:flutter/material.dart';

// ─── MEKAN KATEGORİSİ ─────────────────────────────────────────
enum PlaceCategoryType {
  cafe,
  restaurant,
  park,
  museum,
  monument,
  market,
  bar,
  sports,
  shopping,
  health,
  education,
  transport,
  hotel,
  entertainment,
  nature,
}

extension PlaceCategoryExt on PlaceCategoryType {
  String get label {
    const m = {
      PlaceCategoryType.cafe:          'Kafe',
      PlaceCategoryType.restaurant:    'Restoran',
      PlaceCategoryType.park:          'Park / Yeşil Alan',
      PlaceCategoryType.museum:        'Müze',
      PlaceCategoryType.monument:      'Tarihi Yapı',
      PlaceCategoryType.market:        'Pazar / Market',
      PlaceCategoryType.bar:           'Bar / Gece Hayatı',
      PlaceCategoryType.sports:        'Spor Alanı',
      PlaceCategoryType.shopping:      'Alışveriş',
      PlaceCategoryType.health:        'Sağlık',
      PlaceCategoryType.education:     'Eğitim',
      PlaceCategoryType.transport:     'Ulaşım Noktası',
      PlaceCategoryType.hotel:         'Konaklama',
      PlaceCategoryType.entertainment: 'Eğlence',
      PlaceCategoryType.nature:        'Doğa / Manzara',
    };
    return m[this]!;
  }

  IconData get icon {
    const m = {
      PlaceCategoryType.cafe:          Icons.local_cafe,
      PlaceCategoryType.restaurant:    Icons.restaurant,
      PlaceCategoryType.park:          Icons.park,
      PlaceCategoryType.museum:        Icons.museum,
      PlaceCategoryType.monument:      Icons.account_balance,
      PlaceCategoryType.market:        Icons.storefront,
      PlaceCategoryType.bar:           Icons.nightlife,
      PlaceCategoryType.sports:        Icons.sports_soccer,
      PlaceCategoryType.shopping:      Icons.shopping_bag,
      PlaceCategoryType.health:        Icons.local_hospital,
      PlaceCategoryType.education:     Icons.school,
      PlaceCategoryType.transport:     Icons.directions_bus,
      PlaceCategoryType.hotel:         Icons.hotel,
      PlaceCategoryType.entertainment: Icons.theater_comedy,
      PlaceCategoryType.nature:        Icons.landscape,
    };
    return m[this]!;
  }

  Color get color {
    const m = {
      PlaceCategoryType.cafe:          Color(0xFF8D6E63),
      PlaceCategoryType.restaurant:    Color(0xFFFF7043),
      PlaceCategoryType.park:          Color(0xFF43A047),
      PlaceCategoryType.museum:        Color(0xFF5C6BC0),
      PlaceCategoryType.monument:      Color(0xFF7E57C2),
      PlaceCategoryType.market:        Color(0xFFFFB300),
      PlaceCategoryType.bar:           Color(0xFF1565C0),
      PlaceCategoryType.sports:        Color(0xFF00897B),
      PlaceCategoryType.shopping:      Color(0xFFE91E63),
      PlaceCategoryType.health:        Color(0xFFE53935),
      PlaceCategoryType.education:     Color(0xFF039BE5),
      PlaceCategoryType.transport:     Color(0xFF546E7A),
      PlaceCategoryType.hotel:         Color(0xFF00ACC1),
      PlaceCategoryType.entertainment: Color(0xFFAB47BC),
      PlaceCategoryType.nature:        Color(0xFF558B2F),
    };
    return m[this]!;
  }
}

// ─── MEKAN MODELİ ─────────────────────────────────────────────
class Place {
  final String id;
  final String name;
  final String neighborhood;
  final String district;
  final String province;
  final PlaceCategoryType category;
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  final String? photoUrl;
  final double? rating;        // 1-5 ortalama
  final int reviewCount;
  final int monthlyVisits;
  final bool isTouristSpot;
  final bool isVerified;
  final Map<String, dynamic>? openingHours;
  final DateTime createdAt;

  const Place({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.district,
    required this.province,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    this.photoUrl,
    this.rating,
    this.reviewCount = 0,
    this.monthlyVisits = 0,
    this.isTouristSpot = false,
    this.isVerified = false,
    this.openingHours,
    required this.createdAt,
  });

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    id:            j['id'],
    name:          j['name'],
    neighborhood:  j['neighborhood'],
    district:      j['district'],
    province:      j['province'],
    category:      PlaceCategoryType.values.byName(j['category']),
    latitude:      (j['latitude']  as num).toDouble(),
    longitude:     (j['longitude'] as num).toDouble(),
    address:       j['address'],
    description:   j['description'],
    photoUrl:      j['photo_url'],
    rating:        (j['avg_rating'] as num?)?.toDouble(),
    reviewCount:   (j['review_count'] as num?)?.toInt() ?? 0,
    monthlyVisits: (j['monthly_visits'] as num?)?.toInt() ?? 0,
    isTouristSpot: j['is_tourist_spot'] ?? false,
    isVerified:    j['is_verified'] ?? false,
    openingHours:  j['opening_hours'] as Map<String, dynamic>?,
    createdAt:     DateTime.parse(j['created_at']),
  );
}

// ─── FİLTRE TİPLERİ ──────────────────────────────────────────
enum NeighborhoodFilter {
  overall,        // Genel skor
  tourism,        // Gezilecek yerler
  safety,         // Güvenlik
  nightlife,      // Gece hayatı
  familyFriendly, // Aile dostu
  calm,           // Sakin / Huzurlu
  affordable,     // Uygun fiyatlı
  trending,       // Trend: yükselen
}

extension NeighborhoodFilterExt on NeighborhoodFilter {
  String get label {
    const m = {
      NeighborhoodFilter.overall:        'Genel',
      NeighborhoodFilter.tourism:        'Gezi',
      NeighborhoodFilter.safety:         'Güvenlik',
      NeighborhoodFilter.nightlife:      'Gece Hayatı',
      NeighborhoodFilter.familyFriendly: 'Aile Dostu',
      NeighborhoodFilter.calm:           'Sakin',
      NeighborhoodFilter.affordable:     'Uygun Fiyat',
      NeighborhoodFilter.trending:       '🔥 Trend',
    };
    return m[this]!;
  }

  IconData get icon {
    const m = {
      NeighborhoodFilter.overall:        Icons.star,
      NeighborhoodFilter.tourism:        Icons.explore,
      NeighborhoodFilter.safety:         Icons.shield,
      NeighborhoodFilter.nightlife:      Icons.nightlife,
      NeighborhoodFilter.familyFriendly: Icons.family_restroom,
      NeighborhoodFilter.calm:           Icons.spa,
      NeighborhoodFilter.affordable:     Icons.savings,
      NeighborhoodFilter.trending:       Icons.trending_up,
    };
    return m[this]!;
  }
}

// ─── ROTA MODELİ ─────────────────────────────────────────────
enum RouteType {
  quickWalk,        // 1-2 saat yürüyüş
  coffeeAndWalk,    // Kahve + yürüyüş
  sunset,           // Gün batımı rotası
  studentBudget,    // Öğrenci bütçesi
  familyDay,        // Aile günü
  historicTour,     // Tarihi tur
  foodTour,         // Yemek turu
  nightOut,         // Gece çıkışı
}

extension RouteTypeExt on RouteType {
  String get label {
    const m = {
      RouteType.quickWalk:     '⚡ Hızlı Gezi (1-2 saat)',
      RouteType.coffeeAndWalk: '☕ Kahve + Yürüyüş',
      RouteType.sunset:        '🌅 Gün Batımı Rotası',
      RouteType.studentBudget: '🎓 Öğrenci Bütçesi',
      RouteType.familyDay:     '👨‍👩‍👧 Aile Günü',
      RouteType.historicTour:  '🏛 Tarihi Tur',
      RouteType.foodTour:      '🍽 Yemek Turu',
      RouteType.nightOut:      '🌙 Gece Çıkışı',
    };
    return m[this]!;
  }

  Duration get estimatedDuration {
    const m = {
      RouteType.quickWalk:     Duration(hours: 1, minutes: 30),
      RouteType.coffeeAndWalk: Duration(hours: 2),
      RouteType.sunset:        Duration(hours: 1),
      RouteType.studentBudget: Duration(hours: 3),
      RouteType.familyDay:     Duration(hours: 5),
      RouteType.historicTour:  Duration(hours: 3, minutes: 30),
      RouteType.foodTour:      Duration(hours: 2, minutes: 30),
      RouteType.nightOut:      Duration(hours: 3),
    };
    return m[this]!;
  }

  List<PlaceCategoryType> get preferredCategories {
    switch (this) {
      case RouteType.quickWalk:
        return [PlaceCategoryType.park, PlaceCategoryType.monument, PlaceCategoryType.nature];
      case RouteType.coffeeAndWalk:
        return [PlaceCategoryType.cafe, PlaceCategoryType.park, PlaceCategoryType.nature];
      case RouteType.sunset:
        return [PlaceCategoryType.nature, PlaceCategoryType.monument, PlaceCategoryType.cafe];
      case RouteType.studentBudget:
        return [PlaceCategoryType.park, PlaceCategoryType.market, PlaceCategoryType.cafe, PlaceCategoryType.entertainment];
      case RouteType.familyDay:
        return [PlaceCategoryType.park, PlaceCategoryType.museum, PlaceCategoryType.restaurant, PlaceCategoryType.entertainment];
      case RouteType.historicTour:
        return [PlaceCategoryType.monument, PlaceCategoryType.museum, PlaceCategoryType.education];
      case RouteType.foodTour:
        return [PlaceCategoryType.restaurant, PlaceCategoryType.market, PlaceCategoryType.cafe];
      case RouteType.nightOut:
        return [PlaceCategoryType.bar, PlaceCategoryType.entertainment, PlaceCategoryType.restaurant];
    }
  }
}

class RouteStop {
  final Place place;
  final int orderIndex;
  final Duration suggestedTime;    // bu durakta ne kadar kal
  final String? tip;               // "Akşam üstü gelin, kalabalık olur"

  const RouteStop({
    required this.place,
    required this.orderIndex,
    required this.suggestedTime,
    this.tip,
  });
}

class RecommendedRoute {
  final String id;
  final String name;
  final RouteType type;
  final String neighborhood;
  final List<RouteStop> stops;
  final Duration totalDuration;
  final double totalDistanceKm;
  final String aiSummary;
  final double scoreFit; // 0-100 bu rotanın mahalle skoruyla uyumu

  const RecommendedRoute({
    required this.id,
    required this.name,
    required this.type,
    required this.neighborhood,
    required this.stops,
    required this.totalDuration,
    required this.totalDistanceKm,
    required this.aiSummary,
    required this.scoreFit,
  });
}

// ─── SKOR GEÇMİŞİ ─────────────────────────────────────────────
class ScoreHistoryPoint {
  final DateTime date;
  final double score;
  final int reviewCount;

  const ScoreHistoryPoint({
    required this.date,
    required this.score,
    required this.reviewCount,
  });

  factory ScoreHistoryPoint.fromJson(Map<String, dynamic> j) =>
      ScoreHistoryPoint(
        date:        DateTime.parse(j['recorded_at']),
        score:       (j['overall_score'] as num).toDouble(),
        reviewCount: (j['review_count'] as num?)?.toInt() ?? 0,
      );
}

// ─── ModeRASYON KALEMİ ────────────────────────────────────────
enum ModerationStatus { pending, approved, rejected, flagged }

class ModerationItem {
  final String id;
  final String reviewId;
  final String content;
  final String neighborhood;
  final String? aiReason;    // AI neden işaretledi
  final double? spamScore;   // 0-1
  final ModerationStatus status;
  final DateTime createdAt;

  const ModerationItem({
    required this.id,
    required this.reviewId,
    required this.content,
    required this.neighborhood,
    this.aiReason,
    this.spamScore,
    required this.status,
    required this.createdAt,
  });

  factory ModerationItem.fromJson(Map<String, dynamic> j) => ModerationItem(
    id:           j['id'],
    reviewId:     j['review_id'],
    content:      j['content'],
    neighborhood: j['neighborhood'],
    aiReason:     j['ai_reason'],
    spamScore:    (j['spam_score'] as num?)?.toDouble(),
    status:       ModerationStatus.values.byName(j['status']),
    createdAt:    DateTime.parse(j['created_at']),
  );
}

// ─── KENDİ KONUMU / KOORDİNAT ─────────────────────────────────
class LatLng {
  final double lat;
  final double lng;

  const LatLng(this.lat, this.lng);

  double distanceTo(LatLng other) {
    // Haversine formula (km)
    const r = 6371.0;
    final dLat = _toRad(other.lat - lat);
    final dLng = _toRad(other.lng - lng);
    final a = _sin2(dLat / 2) +
        _cos(lat) * _cos(other.lat) * _sin2(dLng / 2);
    return r * 2 * _asin(_sqrt(a));
  }

  static double _toRad(double d) => d * 3.141592653589793 / 180;
  static double _sin2(double r) => _sin(r) * _sin(r);
  static double _sin(double r) => r - r * r * r / 6;   // Taylor approx.
  static double _cos(double d) {
    final r = _toRad(d);
    return 1 - r * r / 2;
  }
  static double _asin(double x) => x + x * x * x / 6;
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double s = x;
    for (int i = 0; i < 20; i++) s = (s + x / s) / 2;
    return s;
  }
}

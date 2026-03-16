// lib/services/score_engine.dart
// ŞehirSes — Mahalle Skor Motoru
//
// Skor Formülü:
//   totalScore = (turistik_ilgi × 0.20) +
//                (sosyal_hayat  × 0.20) +
//                (kullanıcı_mem × 0.20) +
//                (erişilebilirlik × 0.10) +
//                (temizlik_algısı × 0.10) +
//                (güvenlik_algısı × 0.15) +
//                (aktif_mekan_yo  × 0.05) +
//                (son_dönem_trend × 0.00, sadece momentum bonus/malus)
//
// Her alt skor 0-100 arasında normalize edilir.

import 'dart:math';
import '../models/models.dart';
import '../models/place_models.dart';

/// Alt skor ağırlıkları (toplam = 1.0)
class ScoreWeights {
  static const double touristInterest   = 0.20;
  static const double socialLife        = 0.20;
  static const double userSatisfaction  = 0.20;
  static const double accessibility     = 0.10;
  static const double cleanlinessPerc   = 0.10;
  static const double safetyPerception  = 0.15;
  static const double venueActivityDens = 0.05;
  // Son 30 gün trendi ekstra bonus/malus (±5 puan)
  static const double trendBonus        = 5.0;
}

/// Tek mahalle için hesaplanan detaylı skor
class NeighborhoodScoreResult {
  final double totalScore;          // 0-100
  final double touristInterest;
  final double socialLife;
  final double userSatisfaction;
  final double accessibility;
  final double cleanlinessPerc;
  final double safetyPerception;
  final double venueActivityDens;
  final double trendDelta;          // + ise yükseliyor, - ise düşüyor
  final ScoreColor color;
  final ScoreTrend trend;
  final String label;               // "Harika", "İyi", "Orta", "Zayıf"

  const NeighborhoodScoreResult({
    required this.totalScore,
    required this.touristInterest,
    required this.socialLife,
    required this.userSatisfaction,
    required this.accessibility,
    required this.cleanlinessPerc,
    required this.safetyPerception,
    required this.venueActivityDens,
    required this.trendDelta,
    required this.color,
    required this.trend,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'total_score':        totalScore,
    'tourist_interest':   touristInterest,
    'social_life':        socialLife,
    'user_satisfaction':  userSatisfaction,
    'accessibility':      accessibility,
    'cleanliness':        cleanlinessPerc,
    'safety':             safetyPerception,
    'venue_density':      venueActivityDens,
    'trend_delta':        trendDelta,
    'color':              color.name,
    'label':              label,
  };
}

enum ScoreColor { red, yellow, lightGreen, darkGreen }
enum ScoreTrend { rising, falling, stable }

extension ScoreColorExt on ScoreColor {
  /// Harita polygon rengi
  String get hex {
    switch (this) {
      case ScoreColor.red:        return '#E74C3C';
      case ScoreColor.yellow:     return '#F39C12';
      case ScoreColor.lightGreen: return '#27AE60';
      case ScoreColor.darkGreen:  return '#1E8449';
    }
  }

  double get opacity => 0.55;
}

/// ─── Ana Hesaplama Sınıfı ──────────────────────────────────────
class ScoreEngine {

  // ── 1. TURİSTİK İLGİ ──────────────────────────────────────────
  /// mekan_sayısı, ortalama_beğeni, ziyaret_sıklığı (normalizeli)
  static double calcTouristInterest({
    required int touristPlaceCount,   // kaçe turistik mekan var
    required double avgPlaceLikeRate, // 0-1
    required int monthlyVisits,       // tahminî aylık ziyaret
    int maxVisits = 5000,
  }) {
    final placeScore    = _clamp(touristPlaceCount / 20 * 100);
    final likeScore     = avgPlaceLikeRate * 100;
    final visitScore    = _clamp(monthlyVisits / maxVisits * 100);
    return _clamp(placeScore * 0.4 + likeScore * 0.35 + visitScore * 0.25);
  }

  // ── 2. SOSYAL HAYAT ────────────────────────────────────────────
  /// kafe/restoran/etkinlik/açık_alan/yorum_canlılığı
  static double calcSocialLife({
    required int cafeRestaurantCount,
    required int eventCount,          // son 30 gün etkinlik
    required int openSpaceCount,      // park, meydan vb.
    required double reviewActivityRate, // son 7 gün yorum / toplam yorum
  }) {
    final venueScore    = _clamp(cafeRestaurantCount / 30 * 100);
    final eventScore    = _clamp(eventCount / 10 * 100);
    final spaceScore    = _clamp(openSpaceCount / 5 * 100);
    final activityScore = reviewActivityRate * 100;
    return _clamp(
      venueScore * 0.35 +
      eventScore * 0.25 +
      spaceScore * 0.20 +
      activityScore * 0.20,
    );
  }

  // ── 3. KULLANICI MEMNUNİYETİ ───────────────────────────────────
  /// ham rating ortalaması (1-5) → 0-100 arası
  /// Bayesian smoothing: az yorum yanıltmasın
  static double calcUserSatisfaction({
    required double avgRating,    // 1-5
    required int reviewCount,
    int globalMean = 3,           // prior
    int priorWeight = 15,
  }) {
    // Bayesian average
    final bayesian = (priorWeight * globalMean + reviewCount * avgRating) /
        (priorWeight + reviewCount);
    // 1-5 → 0-100
    return _clamp((bayesian - 1) / 4 * 100);
  }

  // ── 4. ERİŞİLEBİLİRLİK ────────────────────────────────────────
  /// toplu_taşıma yakınlığı + yürüyüş skoru
  static double calcAccessibility({
    required int transitStopCount,  // 500m içi durak sayısı
    required bool hasMetroAccess,
    required double walkScore,      // 0-100 (OSM verisi)
  }) {
    final transitScore = _clamp(transitStopCount / 5 * 100);
    final metroBonus   = hasMetroAccess ? 20.0 : 0.0;
    return _clamp(
      transitScore * 0.40 +
      metroBonus   * 0.30 +
      walkScore    * 0.30,
    );
  }

  // ── 5. TEMİZLİK ALGISI ────────────────────────────────────────
  /// kullanıcı yorumlarından çıkarılan temizlik skoru
  static double calcCleanliness({
    required double cleanlinessRatingAvg,  // 1-5
    required int positiveCleanKeywordCount,
    required int negativeCleanKeywordCount,
    required int reviewCount,
  }) {
    if (reviewCount == 0) return 50.0;
    final ratingScore = (cleanlinessRatingAvg - 1) / 4 * 100;
    final keywordRatio = positiveCleanKeywordCount /
        (positiveCleanKeywordCount + negativeCleanKeywordCount + 1);
    return _clamp(ratingScore * 0.6 + keywordRatio * 100 * 0.4);
  }

  // ── 6. GÜVENLİK ALGISI ────────────────────────────────────────
  /// yorum anahtar kelimeleri + olumsuz yoğunluk
  static double calcSafety({
    required double safetyRatingAvg,
    required int negativeSecurityKeywordCount,
    required int totalReviews,
  }) {
    if (totalReviews == 0) return 60.0; // varsayılan orta
    final ratingScore = (safetyRatingAvg - 1) / 4 * 100;
    // Negatif anahtar kelime yoğunluğu: çok varsa ceza
    final negRatio = negativeSecurityKeywordCount / (totalReviews + 1);
    final penalty  = _clamp(negRatio * 200); // 0-100 arası ceza
    return _clamp(ratingScore - penalty * 0.3);
  }

  // ── 7. AKTİF MEKAN YOĞUNLUĞU ──────────────────────────────────
  static double calcVenueDensity({
    required double areaSqKm,
    required int totalPlaceCount,
  }) {
    if (areaSqKm <= 0) return 50.0;
    final density = totalPlaceCount / areaSqKm;
    // 10 mekan/km² = 50 puan referans noktası
    return _clamp(density / 20 * 100);
  }

  // ── 8. SON DÖNEM TREND HESABLA ─────────────────────────────────
  /// son 30 gün vs önceki 30 gün karşılaştırması
  static double calcTrendDelta({
    required double recentAvgScore,    // son 30 gün ortalama
    required double previousAvgScore,  // önceki 30 gün ortalama
  }) {
    if (previousAvgScore == 0) return 0;
    final delta = recentAvgScore - previousAvgScore;
    return delta.clamp(-ScoreWeights.trendBonus, ScoreWeights.trendBonus);
  }

  // ── TOPLAM SKOR HESAPLA ────────────────────────────────────────
  static NeighborhoodScoreResult calculate({
    required double touristInterest,
    required double socialLife,
    required double userSatisfaction,
    required double accessibility,
    required double cleanlinessPerc,
    required double safetyPerception,
    required double venueActivityDens,
    required double trendDelta,
  }) {
    final weighted = _clamp(
      touristInterest   * ScoreWeights.touristInterest  +
      socialLife        * ScoreWeights.socialLife        +
      userSatisfaction  * ScoreWeights.userSatisfaction  +
      accessibility     * ScoreWeights.accessibility     +
      cleanlinessPerc   * ScoreWeights.cleanlinessPerc   +
      safetyPerception  * ScoreWeights.safetyPerception  +
      venueActivityDens * ScoreWeights.venueActivityDens,
    );

    // Trend bonus/malus (+/-5 puan)
    final total = _clamp(weighted + trendDelta);

    return NeighborhoodScoreResult(
      totalScore:        total,
      touristInterest:   touristInterest,
      socialLife:        socialLife,
      userSatisfaction:  userSatisfaction,
      accessibility:     accessibility,
      cleanlinessPerc:   cleanlinessPerc,
      safetyPerception:  safetyPerception,
      venueActivityDens: venueActivityDens,
      trendDelta:        trendDelta,
      color:             _scoreToColor(total),
      trend:             _deltaToTrend(trendDelta),
      label:             _scoreToLabel(total),
    );
  }

  // ── TOPLU HESAPLAMA (batch) ────────────────────────────────────
  /// Supabase'den gelen ham veriyi alıp tüm mahalleleri hesapla
  static List<NeighborhoodScoreResult> calculateBatch(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map((row) {
      final tourist  = calcTouristInterest(
        touristPlaceCount:   (row['tourist_place_count'] as num?)?.toInt() ?? 0,
        avgPlaceLikeRate:    (row['avg_place_like_rate'] as num?)?.toDouble() ?? 0.5,
        monthlyVisits:       (row['monthly_visits'] as num?)?.toInt() ?? 0,
      );
      final social   = calcSocialLife(
        cafeRestaurantCount: (row['cafe_restaurant_count'] as num?)?.toInt() ?? 0,
        eventCount:          (row['event_count'] as num?)?.toInt() ?? 0,
        openSpaceCount:      (row['open_space_count'] as num?)?.toInt() ?? 0,
        reviewActivityRate:  (row['review_activity_rate'] as num?)?.toDouble() ?? 0.1,
      );
      final userSat  = calcUserSatisfaction(
        avgRating:    (row['avg_rating'] as num?)?.toDouble() ?? 3.0,
        reviewCount:  (row['review_count'] as num?)?.toInt() ?? 0,
      );
      final access   = calcAccessibility(
        transitStopCount: (row['transit_stop_count'] as num?)?.toInt() ?? 1,
        hasMetroAccess:   (row['has_metro_access'] as bool?) ?? false,
        walkScore:        (row['walk_score'] as num?)?.toDouble() ?? 50.0,
      );
      final clean    = calcCleanliness(
        cleanlinessRatingAvg:      (row['cleanliness_avg'] as num?)?.toDouble() ?? 3.0,
        positiveCleanKeywordCount: (row['pos_clean_keywords'] as num?)?.toInt() ?? 0,
        negativeCleanKeywordCount: (row['neg_clean_keywords'] as num?)?.toInt() ?? 0,
        reviewCount:               (row['review_count'] as num?)?.toInt() ?? 0,
      );
      final safety   = calcSafety(
        safetyRatingAvg:               (row['safety_avg'] as num?)?.toDouble() ?? 3.0,
        negativeSecurityKeywordCount:  (row['neg_security_keywords'] as num?)?.toInt() ?? 0,
        totalReviews:                  (row['review_count'] as num?)?.toInt() ?? 0,
      );
      final density  = calcVenueDensity(
        areaSqKm:       (row['area_sq_km'] as num?)?.toDouble() ?? 1.0,
        totalPlaceCount:(row['total_place_count'] as num?)?.toInt() ?? 0,
      );
      final trend    = calcTrendDelta(
        recentAvgScore:   (row['recent_avg_score'] as num?)?.toDouble() ?? 50.0,
        previousAvgScore: (row['previous_avg_score'] as num?)?.toDouble() ?? 50.0,
      );

      return calculate(
        touristInterest:   tourist,
        socialLife:        social,
        userSatisfaction:  userSat,
        accessibility:     access,
        cleanlinessPerc:   clean,
        safetyPerception:  safety,
        venueActivityDens: density,
        trendDelta:        trend,
      );
    }).toList();
  }

  // ── YARDIMCILAR ───────────────────────────────────────────────
  static double _clamp(double v) => v.clamp(0.0, 100.0);

  static ScoreColor _scoreToColor(double score) {
    if (score >= 80) return ScoreColor.darkGreen;
    if (score >= 60) return ScoreColor.lightGreen;
    if (score >= 40) return ScoreColor.yellow;
    return ScoreColor.red;
  }

  static ScoreTrend _deltaToTrend(double delta) {
    if (delta > 1.5)  return ScoreTrend.rising;
    if (delta < -1.5) return ScoreTrend.falling;
    return ScoreTrend.stable;
  }

  static String _scoreToLabel(double score) {
    if (score >= 80) return 'Harika';
    if (score >= 65) return 'İyi';
    if (score >= 50) return 'Orta';
    if (score >= 35) return 'Zayıf';
    return 'Kritik';
  }
}

/// Filtre türüne göre hangi alt skoru baz al
extension FilterScoreMapper on NeighborhoodFilter {
  double scoreFrom(NeighborhoodScoreResult r) {
    switch (this) {
      case NeighborhoodFilter.tourism:    return r.touristInterest;
      case NeighborhoodFilter.safety:     return r.safetyPerception;
      case NeighborhoodFilter.nightlife:  return r.socialLife;
      case NeighborhoodFilter.familyFriendly:
        // Güvenlik + Temizlik ortalaması
        return (r.safetyPerception + r.cleanlinessPerc) / 2;
      case NeighborhoodFilter.calm:
        // Güvenlik yüksek ama sosyal hayat düşük ise sakin
        return (r.safetyPerception * 0.6 + (100 - r.socialLife) * 0.4);
      case NeighborhoodFilter.affordable:
        return r.userSatisfaction; // fiyat verisi olmadığında proxy
      case NeighborhoodFilter.trending:   return r.trendDelta * 10 + 50;
      case NeighborhoodFilter.overall:    return r.totalScore;
    }
  }
}

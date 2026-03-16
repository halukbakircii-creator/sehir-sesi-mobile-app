// lib/models/models.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Kullanıcı Modeli ────────────────────────────────────────────
class User {
  final String id;
  final String tcKimlik;
  final String name;
  final String phone;
  final String province;    // İl: Gaziantep
  final String district;   // İlçe: Şahinbey
  final String neighborhood; // Mahalle: Akkent
  final DateTime createdAt;

  User({
    required this.id,
    required this.tcKimlik,
    required this.name,
    required this.phone,
    required this.province,
    required this.district,
    required this.neighborhood,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    tcKimlik: json['tc_kimlik'],
    name: json['name'],
    phone: json['phone'],
    province: json['province'],
    district: json['district'],
    neighborhood: json['neighborhood'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tc_kimlik': tcKimlik,
    'name': name,
    'phone': phone,
    'province': province,
    'district': district,
    'neighborhood': neighborhood,
    'created_at': createdAt.toIso8601String(),
  };
}

// ─── Geri Bildirim Kategorisi ────────────────────────────────────
enum FeedbackCategory {
  cleaning,
  road,
  security,
  park,
  transport,
  social,
}

extension FeedbackCategoryExtension on FeedbackCategory {
  String get label {
    const labels = {
      FeedbackCategory.cleaning: 'Temizlik / Çevre',
      FeedbackCategory.road: 'Yol / Altyapı',
      FeedbackCategory.security: 'Güvenlik',
      FeedbackCategory.park: 'Park / Yeşil Alan',
      FeedbackCategory.transport: 'Ulaşım',
      FeedbackCategory.social: 'Sosyal Hizmetler',
    };
    return labels[this]!;
  }

  IconData get icon {
    const icons = {
      FeedbackCategory.cleaning: Icons.delete_outline,
      FeedbackCategory.road: Icons.construction,
      FeedbackCategory.security: Icons.security,
      FeedbackCategory.park: Icons.park,
      FeedbackCategory.transport: Icons.directions_bus,
      FeedbackCategory.social: Icons.people,
    };
    return icons[this]!;
  }

  Color get color {
    const colors = {
      FeedbackCategory.cleaning: Color(0xFF27AE60),
      FeedbackCategory.road: Color(0xFFE67E22),
      FeedbackCategory.security: Color(0xFFE74C3C),
      FeedbackCategory.park: Color(0xFF2ECC71),
      FeedbackCategory.transport: Color(0xFF3498DB),
      FeedbackCategory.social: Color(0xFF9B59B6),
    };
    return colors[this]!;
  }
}

// ─── Geri Bildirim Modeli ────────────────────────────────────────
class Feedback {
  final String id;
  final String userId;
  final String province;
  final String district;
  final String neighborhood;
  final FeedbackCategory category;
  final int rating;           // 1-5
  final String comment;
  final String? aiSummary;    // AI tarafından oluşturulan özet
  final String? aiSentiment;  // positive, negative, neutral
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.userId,
    required this.province,
    required this.district,
    required this.neighborhood,
    required this.category,
    required this.rating,
    required this.comment,
    this.aiSummary,
    this.aiSentiment,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) => Feedback(
    id: json['id'],
    userId: json['user_id'],
    province: json['province'],
    district: json['district'],
    neighborhood: json['neighborhood'],
    category: FeedbackCategory.values.byName(json['category']),
    rating: json['rating'],
    comment: json['comment'],
    aiSummary: json['ai_summary'],
    aiSentiment: json['ai_sentiment'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

// ─── Mahalle Memnuniyet Modeli ───────────────────────────────────
class NeighborhoodStats {
  final String neighborhood;
  final String district;
  final String province;
  final double overallScore;      // 0-100
  final int totalFeedbacks;
  final Map<FeedbackCategory, double> categoryScores;
  final List<String> topIssues;
  final List<String> topPraises;
  final String? aiReport;         // AI özet raporu

  NeighborhoodStats({
    required this.neighborhood,
    required this.district,
    required this.province,
    required this.overallScore,
    required this.totalFeedbacks,
    required this.categoryScores,
    required this.topIssues,
    required this.topPraises,
    this.aiReport,
  });

  SatisfactionLevel get satisfactionLevel => getSatisfactionLevel(overallScore);

  // Örnek veri üretici
  static NeighborhoodStats sample(String name, String district) {
    final random = name.hashCode % 100;
    final score = (random % 60 + 30).toDouble();
    return NeighborhoodStats(
      neighborhood: name,
      district: district,
      province: 'Gaziantep',
      overallScore: score,
      totalFeedbacks: 50 + random,
      categoryScores: {
        FeedbackCategory.cleaning: score + 5,
        FeedbackCategory.road: score - 10,
        FeedbackCategory.security: score + 8,
        FeedbackCategory.park: score - 5,
        FeedbackCategory.transport: score + 3,
        FeedbackCategory.social: score + 1,
      },
      topIssues: ['Kaldırım bozuk', 'Çöp toplama geç', 'Park eksik'],
      topPraises: ['Temizlik iyi', 'Güvenlik artmış'],
      aiReport: 'Bu mahallede vatandaşlar genel olarak ${score > 60 ? "memnun" : "memnun değil"}. '
          'En önemli sorun altyapı ve yeşil alan eksikliği olarak öne çıkıyor.',
    );
  }
}

// ─── İlçe Özet Modeli ───────────────────────────────────────────
class DistrictSummary {
  final String district;
  final String province;
  final double overallScore;
  final int totalFeedbacks;
  final List<NeighborhoodStats> neighborhoods;

  DistrictSummary({
    required this.district,
    required this.province,
    required this.overallScore,
    required this.totalFeedbacks,
    required this.neighborhoods,
  });
}

// ─── Belediye Raporu ────────────────────────────────────────────
class MunicipalityReport {
  final String province;
  final DateTime generatedAt;
  final double overallScore;
  final List<DistrictSummary> districts;
  final List<String> criticalIssues;
  final List<String> recommendations;
  final String aiExecutiveSummary;

  MunicipalityReport({
    required this.province,
    required this.generatedAt,
    required this.overallScore,
    required this.districts,
    required this.criticalIssues,
    required this.recommendations,
    required this.aiExecutiveSummary,
  });
}

// ─── Örnek Türkiye İlleri Verisi ────────────────────────────────
class TurkeyData {
  static const List<String> provinces = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray',
    'Amasya', 'Ankara', 'Antalya', 'Ardahan', 'Artvin',
    'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt',
    'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur',
    'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli',
    'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
    'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
    'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul',
    'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars',
    'Kastamonu', 'Kayseri', 'Kilis', 'Kırıkkale', 'Kırklareli',
    'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya',
    'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
    'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize',
    'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas',
    'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon',
    'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
  ];

  static const Map<String, List<String>> districts = {
    'Gaziantep': [
      'Şahinbey', 'Şehitkamil', 'Nizip', 'İslahiye', 'Nurdağı',
      'Oğuzeli', 'Araban', 'Karkamış', 'Yavuzeli',
    ],
    'İstanbul': [
      'Kadıköy', 'Beşiktaş', 'Şişli', 'Üsküdar', 'Fatih',
      'Beyoğlu', 'Bakırköy', 'Maltepe', 'Pendik',
    ],
    'Ankara': [
      'Çankaya', 'Keçiören', 'Yenimahalle', 'Mamak', 'Etimesgut',
      'Sincan', 'Altındağ', 'Pursaklar', 'Gölbaşı',
    ],
  };

  static const Map<String, List<String>> neighborhoods = {
    'Şahinbey': [
      'Akkent', 'Bağlarbaşı', 'Çukuryurt', 'Eminbey', 'Fevzipaşa',
      'Gazikent', 'Güneykent', 'İncilipınar', 'Karataş', 'Mücahitler',
      'Onur', 'Özgürevler', 'Sakarya', 'Sultanbey', 'Törehan',
    ],
    'Şehitkamil': [
      'Bahçelievler', 'Barak', 'Burç', 'Doğukent', 'Düztepe',
      'Eski Barak', 'Gazi', 'Gündoğdu', 'Karagöz', 'Köroğlu',
    ],
  };
}

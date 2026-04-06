import 'package:flutter/material.dart';

// ─── Geri Bildirim Kategorileri ─────────────────────────────────
enum FeedbackCategory { cleaning, road, security, park, transport, social }

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

  // BUG #6 FIX: IconData yerine emoji String kullan
  String get emoji {
    const emojis = {
      FeedbackCategory.cleaning: '🧹',
      FeedbackCategory.road: '🛣️',
      FeedbackCategory.security: '🔒',
      FeedbackCategory.park: '🌳',
      FeedbackCategory.transport: '🚌',
      FeedbackCategory.social: '🤝',
    };
    return emojis[this]!;
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
      FeedbackCategory.cleaning: Color(0xFF4ADE80),
      FeedbackCategory.road: Color(0xFFFB923C),
      FeedbackCategory.security: Color(0xFF38BDF8),
      FeedbackCategory.park: Color(0xFF34D399),
      FeedbackCategory.transport: Color(0xFFC084FC),
      FeedbackCategory.social: Color(0xFFF472B6),
    };
    return colors[this]!;
  }
}

// ─── Mahalle İstatistikleri ──────────────────────────────────────
class NeighborhoodStats {
  final String neighborhood;
  final String district;
  final String province;
  final double overallScore;
  final int totalFeedbacks;
  final Map<FeedbackCategory, double> categoryScores;
  final List<String> topIssues;
  final List<String> topPraises;
  final String? aiReport;

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

  static NeighborhoodStats sample(String name, String district) {
    final random = name.hashCode.abs() % 60 + 30;
    final score = random.toDouble();
    return NeighborhoodStats(
      neighborhood: name,
      district: district,
      province: TurkeyData.provinceOfDistrict(district),
      overallScore: score,
      totalFeedbacks: 20 + (name.hashCode.abs() % 80),
      categoryScores: {
        FeedbackCategory.cleaning: (score + 5).clamp(10, 100),
        FeedbackCategory.road: (score - 10).clamp(10, 100),
        FeedbackCategory.security: (score + 8).clamp(10, 100),
        FeedbackCategory.park: (score - 5).clamp(10, 100),
        FeedbackCategory.transport: (score + 3).clamp(10, 100),
        FeedbackCategory.social: (score + 1).clamp(10, 100),
      },
      topIssues: ['Kaldırım bozuk', 'Yeşil alan eksik'],
      topPraises: ['Temizlik iyi', 'Güvenlik artmış'],
      aiReport: null,
    );
  }
}

// ─── Diğer modeller ──────────────────────────────────────────────
class DistrictSummary {
  final String district;
  final String province;
  final double overallScore;
  final int totalFeedbacks;
  final List<NeighborhoodStats> neighborhoods;
  DistrictSummary({required this.district, required this.province,
    required this.overallScore, required this.totalFeedbacks, required this.neighborhoods});
}

class MunicipalityReport {
  final String province;
  final DateTime generatedAt;
  final double overallScore;
  final List<DistrictSummary> districts;
  final List<String> criticalIssues;
  final List<String> recommendations;
  final String aiExecutiveSummary;
  MunicipalityReport({required this.province, required this.generatedAt,
    required this.overallScore, required this.districts, required this.criticalIssues,
    required this.recommendations, required this.aiExecutiveSummary});
}

// ─── Satisfaction ────────────────────────────────────────────────
enum SatisfactionLevel { high, medium, low, noData }

extension SatisfactionExtension on SatisfactionLevel {
  Color get color {
    switch (this) {
      case SatisfactionLevel.high:   return const Color(0xFF4ADE80);
      case SatisfactionLevel.medium: return const Color(0xFFFBBF24);
      case SatisfactionLevel.low:    return const Color(0xFFF87171);
      case SatisfactionLevel.noData: return const Color(0xFF475569);
    }
  }
  String get label {
    switch (this) {
      case SatisfactionLevel.high:   return 'Memnun';
      case SatisfactionLevel.medium: return 'Orta';
      case SatisfactionLevel.low:    return 'Memnun Değil';
      case SatisfactionLevel.noData: return 'Veri Yok';
    }
  }
  String get emoji {
    switch (this) {
      case SatisfactionLevel.high:   return '😊';
      case SatisfactionLevel.medium: return '😐';
      case SatisfactionLevel.low:    return '😞';
      case SatisfactionLevel.noData: return '❓';
    }
  }
}

SatisfactionLevel getSatisfactionLevel(double score) {
  if (score >= 70) return SatisfactionLevel.high;
  if (score >= 40) return SatisfactionLevel.medium;
  if (score > 0)   return SatisfactionLevel.low;
  return SatisfactionLevel.noData;
}

// ─── BUG #10 & #14 FIX: TurkeyData — 81 İLİN TÜMÜ ──────────────
class TurkeyData {
  static const List<String> provinces = [
    'Adana','Adıyaman','Afyonkarahisar','Ağrı','Aksaray','Amasya',
    'Ankara','Antalya','Ardahan','Artvin','Aydın','Balıkesir',
    'Bartın','Batman','Bayburt','Bilecik','Bingöl','Bitlis',
    'Bolu','Burdur','Bursa','Çanakkale','Çankırı','Çorum',
    'Denizli','Diyarbakır','Düzce','Edirne','Elazığ','Erzincan',
    'Erzurum','Eskişehir','Gaziantep','Giresun','Gümüşhane',
    'Hakkari','Hatay','Iğdır','Isparta','İstanbul','İzmir',
    'Kahramanmaraş','Karabük','Karaman','Kars','Kastamonu',
    'Kayseri','Kilis','Kırıkkale','Kırklareli','Kırşehir',
    'Kocaeli','Konya','Kütahya','Malatya','Manisa','Mardin',
    'Mersin','Muğla','Muş','Nevşehir','Niğde','Ordu',
    'Osmaniye','Rize','Sakarya','Samsun','Siirt','Sinop',
    'Sivas','Şanlıurfa','Şırnak','Tekirdağ','Tokat','Trabzon',
    'Tunceli','Uşak','Van','Yalova','Yozgat','Zonguldak',
  ];

  static const Map<String, List<String>> districts = {
    'Adana': ['Seyhan','Yüreğir','Çukurova','Sarıçam','Ceyhan','Kozan','İmamoğlu','Karataş','Yumurtalık','Aladağ','Feke','Karaisalı','Pozantı','Saimbeyli','Tufanbeyli'],
    'Adıyaman': ['Merkez','Kahta','Besni','Gölbaşı','Samsat','Sincik','Tut','Gerger'],
    'Afyonkarahisar': ['Merkez','Sandıklı','Dinar','Emirdağ','Bolvadin','Çay','Sultandağı','Şuhut','Dazkırı','İscehisar','Bayat','Başmakçı','Evciler','Hocalar','Kızılören'],
    'Ağrı': ['Merkez','Patnos','Doğubayazıt','Diyadin','Eleşkirt','Hamur','Taşlıçay','Tutak'],
    'Aksaray': ['Merkez','Eskil','Ortaköy','Ağaçören','Gülagaç','Güzelyurt','Sarıyahşi'],
    'Amasya': ['Merkez','Merzifon','Suluova','Taşova','Gümüşhacıköy','Hamamözü','Göynücek','Vezirköprü'],
    'Ankara': ['Çankaya','Keçiören','Yenimahalle','Mamak','Etimesgut','Sincan','Altındağ','Pursaklar','Gölbaşı','Kahramankazan','Beypazarı','Ayaş','Bala','Çamlıdere','Çubuk','Elmadağ','Evren','Güdül','Haymana','Kalecik','Kızılcahamam','Nallıhan','Polatlı','Şereflikoçhisar'],
    'Antalya': ['Muratpaşa','Konyaaltı','Kepez','Alanya','Manavgat','Serik','Aksu','Döşemealtı','Korkuteli','Kumluca','Finike','Gazipaşa','Gündoğmuş','İbradı','Kaş','Kemer','Akseki','Elmalı','Demre'],
    'Ardahan': ['Merkez','Göle','Çıldır','Damal','Hanak','Posof'],
    'Artvin': ['Merkez','Hopa','Arhavi','Borçka','Murgul','Şavşat','Yusufeli','Ardanuç'],
    'Aydın': ['Efeler','Nazilli','Söke','Kuşadası','Didim','İncirliova','Germencik','Koçarlı','Kuyucak','Sultanhisar','Bozdoğan','Buharkent','Çine','Karacasu','Karpuzlu','Köşk','Yenipazar'],
    'Balıkesir': ['Altıeylül','Karesi','Bandırma','Edremit','Burhaniye','Gönen','Bigadiç','Dursunbey','Erdek','İvrindi','Kepsut','Manyas','Marmara','Pamukçu','Savaştepe','Sındırgı','Susurluk'],
    'Bartın': ['Merkez','Amasra','Kurucaşile','Ulus'],
    'Batman': ['Merkez','Kozluk','Sason','Beşiri','Gercüş','Hasankeyf','Kayapınar'],
    'Bayburt': ['Merkez','Aydıntepe','Demirözü'],
    'Bilecik': ['Merkez','Bozüyük','Söğüt','Gölpazarı','İnhisar','Osmaneli','Pazaryeri','Yenipazar'],
    'Bingöl': ['Merkez','Genç','Solhan','Adaklı','Karlıova','Kiğı','Yayladere','Yedisu'],
    'Bitlis': ['Merkez','Tatvan','Ahlat','Adilcevaz','Güroymak','Hizan','Mutki'],
    'Bolu': ['Merkez','Gerede','Mudurnu','Göynük','Kıbrıscık','Mengen','Seben','Dörtdivan','Yeniçağa'],
    'Burdur': ['Merkez','Bucak','Gölhisar','Tefenni','Altınyayla','Çavdır','Çeltikçi','Karamanlı','Kemer','Yeşilova'],
    'Bursa': ['Osmangazi','Nilüfer','Yıldırım','İnegöl','Gemlik','Mudanya','Orhangazi','Mustafakemalpaşa','Karacabey','İznik','Kestel','Büyükorhan','Gürsu','Harmancık','Keles','Orhaneli'],
    'Çanakkale': ['Merkez','Biga','Gelibolu','Çan','Ayvacık','Bayramiç','Bozcaada','Eceabat','Ezine','Gökçeada','Lapseki','Yenice'],
    'Çankırı': ['Merkez','Çerkeş','Ilgaz','Kurşunlu','Atkaracalar','Bayramören','Eldivan','Kızılırmak','Orta','Şabanözü','Yapraklı'],
    'Çorum': ['Merkez','Alaca','Sungurlu','Osmancık','Boğazkale','İskilip','Kargı','Laçin','Mecitözü','Oğuzlar','Ortaköy','Uğurludağ'],
    'Denizli': ['Pamukkale','Merkezefendi','Çivril','Sarayköy','Acıpayam','Buldan','Güney','Honaz','Kale','Serinhisar','Tavas','Babadağ','Baklan','Bekilli','Beyağaç','Bozkurt','Cameli','Çameli','Çardak'],
    'Diyarbakır': ['Bağlar','Kayapınar','Sur','Yenişehir','Bismil','Çermik','Çınar','Çüngüş','Dicle','Eğil','Ergani','Hani','Hazro','Kocaköy','Kulp','Lice','Silvan'],
    'Düzce': ['Merkez','Akçakoca','Kaynaşlı','Cumayeri','Çilimli','Gölyaka','Gümüşova','Yığılca'],
    'Edirne': ['Merkez','Keşan','Uzunköprü','İpsala','Enez','Havsa','Lalapaşa','Meriç','Süloğlu'],
    'Elazığ': ['Merkez','Kovancılar','Karakoçan','Palu','Arıcak','Baskil','Keban','Maden','Sivrice','Alacakaya','Ağın'],
    'Erzincan': ['Merkez','Refahiye','Tercan','Üzümlü','Çayırlı','İliç','Kemah','Kemaliye','Otlukbeli'],
    'Erzurum': ['Yakutiye','Palandöken','Aziziye','Oltu','Horasan','İspir','Karayazı','Narman','Olur','Pasinler','Pazaryolu','Şenkaya','Tekman','Tortum','Uzundere','Aşkale','Çat','Hınıs','Karaçoban'],
    'Eskişehir': ['Tepebaşı','Odunpazarı','Sivrihisar','Alpu','Beylikova','Çifteler','Günyüzü','Han','İnönü','Mahmudiye','Mihalgazi','Mihalıççık','Sarıcakaya','Seyitgazi'],
    'Gaziantep': ['Şahinbey','Şehitkamil','Nizip','İslahiye','Nurdağı','Oğuzeli','Araban','Karkamış','Yavuzeli'],
    'Giresun': ['Merkez','Bulancak','Espiye','Tirebolu','Alucra','Çamoluk','Çanakçı','Dereli','Doğankent','Eynesil','Görele','Güce','Keşap','Piraziz','Şebinkarahisar','Yağlıdere'],
    'Gümüşhane': ['Merkez','Kelkit','Şiran','Köse','Kürtün','Torul'],
    'Hakkari': ['Merkez','Yüksekova','Şemdinli','Çukurca','Derecik'],
    'Hatay': ['Antakya','İskenderun','Dörtyol','Reyhanlı','Kırıkhan','Samandağ','Erzin','Arsuz','Defne','Altınözü','Belen','Hassa','Kumlu','Payas','Yayladağı'],
    'Iğdır': ['Merkez','Aralık','Tuzluca','Karakoyunlu'],
    'Isparta': ['Merkez','Eğirdir','Yalvaç','Aksu','Atabey','Gelendost','Gönen','Keçiborlu','Senirkent','Sütçüler','Şarkikaraağaç','Uluborlu','Yenişarbademli'],
    'İstanbul': ['Kadıköy','Beşiktaş','Şişli','Üsküdar','Fatih','Beyoğlu','Bakırköy','Maltepe','Pendik','Ümraniye','Bağcılar','Güngören','Bahçelievler','Bağcılar','Bayrampaşa','Esenler','Gaziosmanpaşa','Kağıthane','Sarıyer','Zeytinburnu','Arnavutköy','Ataşehir','Avcılar','Başakşehir','Bayrampaşa','Beykoz','Büyükçekmece','Çatalca','Çekmeköy','Esenyurt','Eyüpsultan','Kartal','Küçükçekmece','Silivri','Sultanbeyli','Sultangazi','Şile','Tuzla'],
    'İzmir': ['Konak','Karşıyaka','Bornova','Buca','Bayraklı','Çiğli','Gaziemir','Karabağlar','Narlıdere','Balçova','Aliağa','Bergama','Beydağ','Çeşme','Dikili','Foça','Güzelbahçe','Karaburun','Kemalpaşa','Kınık','Kiraz','Menderes','Menemen','Ödemiş','Seferihisar','Selçuk','Tire','Torbalı','Urla'],
    'Kahramanmaraş': ['Dulkadiroğlu','Onikişubat','Elbistan','Afşin','Göksun','Andırın','Çağlayancerit','Ekinözü','Nurhak','Pazarcık','Türkoğlu'],
    'Karabük': ['Merkez','Safranbolu','Eskipazar','Eflani','Ovacık','Yenice'],
    'Karaman': ['Merkez','Ermenek','Sarıveliler','Ayrancı','Başyayla','Kazımkarabekir'],
    'Kars': ['Merkez','Sarıkamış','Kağızman','Arpaçay','Akyaka','Digor','Selim','Susuz'],
    'Kastamonu': ['Merkez','Tosya','Taşköprü','Cide','Araç','Boyabat','Abana','Ağlı','Azdavay','Bozkurt','Çatalzeytin','Daday','Devrekani','Doğanyurt','Hanönü','İhsangazi','İnebolu','Küre','Pınarbaşı','Seydiler','Şenpazar','Türkeli'],
    'Kayseri': ['Melikgazi','Kocasinan','Talas','Develi','Yahyalı','Bünyan','Felahiye','Hacılar','İncesu','Özvatan','Pınarbaşı','Sarıoğlan','Sarız','Tomarza','Yeşilhisar'],
    'Kilis': ['Merkez','Musabeyli','Polateli','Elbeyli'],
    'Kırıkkale': ['Merkez','Delice','Sulakyurt','Bahşili','Balışeyh','Çelebi','Karakeçili','Keskin','Yahşihan'],
    'Kırklareli': ['Merkez','Lüleburgaz','Babaeski','Pehlivanköy','Büyükkarıştıran','Demirköy','Kofçaz','Pınarhisar','Vize'],
    'Kırşehir': ['Merkez','Kaman','Mucur','Akçakent','Akpınar','Boztepe','Çiçekdağı'],
    'Kocaeli': ['İzmit','Gebze','Darıca','Derince','Gölcük','Körfez','Başiskele','Çayırova','Dilovası','Kandıra','Karamürsel','Kartepe'],
    'Konya': ['Selçuklu','Meram','Karatay','Ereğli','Akşehir','Beyşehir','Seydişehir','Çumra','Ilgın','Kulu','Sarayönü','Yunak','Akören','Altınekin','Bozkır','Cihanbeyli','Derbent','Derebucak','Doğanhisar','Emirgazi','Güneysınır','Hadim','Halkapınar','Hüyük','Kadınhanı','Karapınar','Taşkent','Tuzlukçu'],
    'Kütahya': ['Merkez','Simav','Tavşanlı','Gediz','Altıntaş','Aslanapa','Çavdarhisar','Domaniç','Dumlupınar','Emet','Hisarcık','Pazarlar','Şaphane'],
    'Malatya': ['Battalgazi','Yeşilyurt','Darende','Doğanşehir','Akçadağ','Arguvan','Arapgir','Doğanyol','Hekimhan','Kale','Kuluncak','Pütürge','Yazıhan'],
    'Manisa': ['Şehzadeler','Yunusemre','Akhisar','Turgutlu','Salihli','Soma','Alaşehir','Saruhanlı','Ahmetli','Demirci','Gölmarmara','Gördes','Kırkağaç','Köprübaşı','Kula','Selendi'],
    'Mardin': ['Artuklu','Kızıltepe','Nusaybin','Midyat','Derik','Mazıdağı','Ömerli','Savur','Dargeçit','Yeşilli'],
    'Mersin': ['Yenişehir','Toroslar','Akdeniz','Mezitli','Tarsus','Erdemli','Silifke','Anamur','Mut','Aydıncık','Bozyazı','Çamlıyayla','Gülnar'],
    'Muğla': ['Menteşe','Bodrum','Fethiye','Marmaris','Milas','Seydikemer','Ula','Datça','İzmir','Kavaklıdere','Köyceğiz','Ortaca','Yatağan'],
    'Muş': ['Merkez','Malazgirt','Varto','Bulanık','Hasköy','Korkut'],
    'Nevşehir': ['Merkez','Ürgüp','Avanos','Gülşehir','Acıgöl','Derinkuyu','Hacıbektaş','Kozaklı'],
    'Niğde': ['Merkez','Bor','Çiftlik','Altunhisar','Ulukışla','Çamardı'],
    'Ordu': ['Altınordu','Ünye','Fatsa','Perşembe','Akkuş','Aybastı','Çamaş','Çatalpınar','Çaybaşı','Gölköy','Gülyalı','Gürgentepe','İkizce','Kabadüz','Kabataş','Korgan','Kumru','Mesudiye','Ulubey'],
    'Osmaniye': ['Merkez','Kadirli','Düziçi','Bahçe','Hasanbeyli','Sumbas','Toprakkale'],
    'Rize': ['Merkez','Ardeşen','Çayeli','Fındıklı','İkizdere','Kalkandere','Pazar','Çamlıhemşin','Derepazarı','Güneysu','Hemşin','İyidere'],
    'Sakarya': ['Adapazarı','Serdivan','Erenler','Arifiye','Akyazı','Ferizli','Geyve','Hendek','Karapürçek','Karasu','Kaynarca','Kocaali','Pamukova','Sapanca','Söğütlü','Taraklı'],
    'Samsun': ['Atakum','İlkadım','Canik','Tekkeköy','Bafra','Çarşamba','Vezirköprü','Terme','Alaçam','Asarcık','Ayvacık','Havza','Kavak','Ladik','Ondokuzmayıs','Salıpazarı','Yakakent'],
    'Siirt': ['Merkez','Kurtalan','Baykan','Eruh','Pervari','Şirvan','Tillo'],
    'Sinop': ['Merkez','Boyabat','Gerze','Ayancık','Dikmen','Durağan','Erfelek','Saraydüzü','Türkeli'],
    'Sivas': ['Merkez','Şarkışla','Kangal','Zara','Divriği','Gemerek','Gürün','Hafik','İmranlı','Koyulhisar','Suşehri','Ulaş','Yıldızeli','Altınyayla','Akıncılar','Doğanşar','Gölova'],
    'Şanlıurfa': ['Karaköprü','Haliliye','Eyyübiye','Viranşehir','Birecik','Bozova','Ceylanpınar','Halfeti','Harran','Hilvan','Siverek','Suruç'],
    'Şırnak': ['Merkez','Cizre','Silopi','İdil','Beytüşşebap','Güçlükonak','Uludere'],
    'Tekirdağ': ['Süleymanpaşa','Çorlu','Çerkezköy','Muratlı','Ergene','Malkara','Hayrabolu','Marmaraereğlisi','Saray','Şarköy'],
    'Tokat': ['Merkez','Niksar','Turhal','Erbaa','Almus','Artova','Başçiftlik','Çarşamba','Pazar','Reşadiye','Sulusaray','Yeşilyurt','Zile'],
    'Trabzon': ['Ortahisar','Akçaabat','Araklı','Of','Yomra','Arsin','Beşikdüzü','Çaykara','Dernekpazarı','Düzköy','Hayrat','Köprübaşı','Maçka','Pelitli','Sürmene','Şalpazarı','Tonya','Vakfıkebir'],
    'Tunceli': ['Merkez','Pertek','Çemişgezek','Hozat','Mazgirt','Nazimiye','Ovacık','Pülümür'],
    'Uşak': ['Merkez','Banaz','Eşme','Karahallı','Sivaslı','Ulubey'],
    'Van': ['İpekyolu','Tuşba','Edremit','Erciş','Gevaş','Gürpınar','Bahçesaray','Başkale','Çaldıran','Çatak','Kabalan','Özalp','Saray','Muradiye'],
    'Yalova': ['Merkez','Çınarcık','Altınova','Armutlu','Çiftlikkoy','Termal'],
    'Yozgat': ['Merkez','Sorgun','Akdağmadeni','Yerköy','Boğazlıyan','Aydıncık','Çandır','Çayıralan','Çekerek','Kadışehri','Saraykent','Sarayyahşi','Şefaatli'],
    'Zonguldak': ['Merkez','Ereğli','Çaycuma','Devrek','Alaplı','Gökçebey','Kilimli','Kozlu'],
  };

  static const Map<String, List<String>> neighborhoods = {
    'Şahinbey': ['Akkent','Bağlarbaşı','Çukuryurt','Eminbey','Fevzipaşa','Gazikent','Güneykent','İncilipınar','Karataş','Mücahitler','Onur','Özgürevler','Sakarya','Sultanbey','Törehan'],
    'Şehitkamil': ['Bahçelievler','Barak','Burç','Doğukent','Düztepe','Eski Barak','Gazi','Gündoğdu','Karagöz','Köroğlu'],
    'Çankaya': ['Ayrancı','Bahçelievler','Balgat','Çukurambar','Emek','Kavaklıdere','Kızılay','Oran'],
    'Kadıköy': ['Caferağa','Fenerbahçe','Göztepe','Moda','Osmanağa','Suadiye'],
    'Konak': ['Alsancak','Basmane','Çankaya','Kahramanlar'],
    'Muratpaşa': ['Bahçelievler','Balbey','Çağlayan','Fener','Güvenlik'],
    'Melikgazi': ['Anbar','Bağpınar','Gesi','Hunat','Mimarsinan'],
    'Selçuklu': ['Aslantepe','Bosna Hersek','Feritpaşa','Kılıçaslan'],
  };

  // İlçenin hangi ile ait olduğunu bul
  static String provinceOfDistrict(String district) {
    for (final entry in districts.entries) {
      if (entry.value.contains(district)) return entry.key;
    }
    return 'Türkiye';
  }
}

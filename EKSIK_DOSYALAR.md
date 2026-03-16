# ŞehirSes — Eksik Dosyalar ve Entegrasyon Rehberi

Bu paket, mevcut kodunuzda tespit edilen **kritik eksikleri** kapatır.

---

## 📁 Yeni Dosyalar

| Dosya | Amaç |
|-------|------|
| `lib/models/place_models.dart` | Mekan, Filtre, Rota, Moderasyon modelleri |
| `lib/services/score_engine.dart` | **Çok boyutlu skor formülü** |
| `lib/services/filter_service.dart` | Filtre state yönetimi (ChangeNotifier) |
| `lib/services/places_service.dart` | Supabase mekan/favori/rota API'si |
| `lib/services/route_service.dart` | AI destekli rota öneri motoru |
| `lib/screens/city_selection_screen.dart` | Şehir seçim ekranı (onboarding) |
| `lib/screens/route_screen.dart` | Rota görüntüleme UI'ı |
| `supabase/migrations/002_extended_schema.sql` | Places, score_history, favoriler, moderasyon |
| `supabase/seed/istanbul_seed.sql` | 25 İstanbul mahallesi + 20 popüler mekan |
| `supabase/functions/recalculate-scores/index.ts` | Gece skor yeniden hesaplama |
| `pubspec.yaml` | Güncellenmiş paket bağımlılıkları |

---

## 🔧 Entegrasyon Adımları

### 1. Veritabanı (Supabase Dashboard → SQL Editor)

```bash
# Önce mevcut 001 migration'ı çalıştırın (zaten çalışıyorsa atlayın)
# Sonra sırayla:
supabase/migrations/002_extended_schema.sql
supabase/seed/istanbul_seed.sql
```

### 2. Edge Function Deploy

```bash
supabase functions deploy recalculate-scores
```

Cron job ekleyin (Supabase → Database → Extensions → pg_cron):
```sql
SELECT cron.schedule(
  'nightly-score-recalc',
  '0 2 * * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.edge_function_url') || '/recalculate-scores',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{"province": "İstanbul"}'::jsonb
  )$$
);
```

### 3. Flutter — Provider'lara ekle

`main.dart` içinde `MultiProvider` kullanın:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => FilterService()),
    Provider(create: (_) => PlacesService()),
    Provider(create: (_) => RouteService()),
  ],
  child: const SehirSesApp(),
)
```

### 4. AppRouter'ı güncelleyin

`main_updated.dart`'ı kullanıyorsanız, `GuestHomeScreen`'e geçişten önce
ilk açılışta `CitySelectionScreen`'e yönlendirin:

```dart
// İlk açılışı kontrol et
final prefs = await SharedPreferences.getInstance();
final hasCity = prefs.getString('selected_city') != null;

if (!hasCity) {
  return const CitySelectionScreen(isFirstTime: true);
}
return const GuestHomeScreen();
```

### 5. HomeScreen'e `initialCity` parametresi ekleyin

`home_screen.dart`'ı şu şekilde güncelleyin:

```dart
class HomeScreen extends StatefulWidget {
  final String initialCity;
  const HomeScreen({super.key, this.initialCity = 'İstanbul'});
  ...
}
```

---

## 🧮 Skor Formülü Açıklaması

`score_engine.dart` içindeki formül:

```
ToplamSkor = 
  turistikİlgi       × 0.20  ← mekan sayısı + beğeni + ziyaret
  sosyalHayat        × 0.20  ← kafe/restoran + etkinlik + açık alan
  kullanıcıMemnun    × 0.20  ← Bayesian ortalama rating
  erişilebilirlik    × 0.10  ← toplu taşıma + metro + yürüyüş
  temizlikAlgısı     × 0.10  ← temizlik rating + anahtar kelimeler
  güvenlikAlgısı     × 0.15  ← güvenlik rating − negatif kelimeler
  mekanYoğunluğu     × 0.05  ← mekan/km²
  + trendBonus (±5)           ← son 30 gün karşılaştırması
```

**Renk eşiği:**
- 🔴 0–39: Kritik
- 🟡 40–59: Zayıf/Orta
- 🟢 60–79: İyi
- 💚 80–100: Harika

---

## 🗺️ Harita Entegrasyonu (Eksik Kalan)

`flutter_map` paketi kurulu. Mahalle polygon'ları için GeoJSON dosyalarını
`assets/geojson/istanbul.geojson` olarak ekleyin.

OSM'den İstanbul GeoJSON alma:
```bash
# overpass-turbo.eu'da sorgulayın:
# [out:json]; relation["admin_level"="10"]["name"~"mahalle"]["addr:city"="İstanbul"]; out geom;
```

Harita renklendirmesi için `score_engine.dart`'taki `ScoreColor.hex` kullanın.

---

## 🚨 Kritik Notlar

1. **API Key güvenliği:** `ai_service.dart`'taki `YOUR_ANTHROPIC_API_KEY` kaldırın.
   Supabase Edge Function'larda environment variable kullanın.

2. **RLS:** Tüm tablolarda Row Level Security açık. Test sırasında
   `service_role` key kullandığınızdan emin olun.

3. **İlk veri:** Istanbul seed çalıştırmadan önce `001_initial_schema.sql`'nin
   çalışmış olması gerekiyor.

4. **Moderasyon kuyruğu:** `recalculate-scores` Edge Function otomatik olarak
   `analyze-feedback`'i tetiklemez. İki fonksiyon bağımsız çalışır.
   Admin panelinden moderasyon kuyruğunu manuel yönetin.

5. **Skor geçmişi snapshot:** `record_daily_score_snapshot()` fonksiyonu
   ancak cron kurulduktan sonra çalışır. İlk test için manuel çağırın:
   ```sql
   SELECT record_daily_score_snapshot();
   ```

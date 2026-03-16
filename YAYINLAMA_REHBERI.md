# ŞehirSes — Yayınlama Rehberi

Bu dosya, uygulamayı production'a almak için yapmanız gereken **manuel adımları** anlatır.
Tüm kod düzeltmeleri tamamlandı.

---

## ✅ Düzeltilen Her Şey (kod değişikliği gerekmez)

### Güvenlik
- [x] `ai_service.dart` → API key `.env`'den okunuyor (hardcoded yoktur)
- [x] `.gitignore` → `.env`, `google-services.json`, `GoogleService-Info.plist` git dışı

### Mimari / Yapı
- [x] `main.dart` → `MultiProvider` (FilterService, PlacesService, RouteService, AuthService)
- [x] `main.dart` → Firebase + dotenv başlatma eklendi
- [x] `lib/router/app_router.dart` → go_router tam yapılandırması
- [x] `lib/services/notification_service.dart` → FCM handler, token kayıt

### İlk Açılış Akışı
- [x] `main.dart` → SharedPreferences ile ilk açılış kontrolü → CitySelectionScreen
- [x] `city_selection_screen.dart` → Seçilen şehir artık SharedPreferences'a kaydediliyor
- [x] `lib/screens/address_setup_screen.dart` → Eksik dosya oluşturuldu (login sonrası adres ayarlama)

### Veri / Backend
- [x] `home_screen.dart` → Supabase'den gerçek veri çekiyor (mock data fallback ile)
- [x] `feedback_screen.dart` → Supabase'e kaydediyor + AI analizi + giriş kontrolü
- [x] `municipality_dashboard_screen.dart` → Supabase'den dinamik veri + kullanıcı iline göre
- [x] Tüm async fonksiyonlarda `!mounted` guard eklendi

### UI
- [x] `home_screen.dart` → Asistan sekmesi (AI chatbot arayüzü) implemente edildi
- [x] `home_screen.dart` → Profil sekmesi (konum, telefon, çıkış, konum değiştirme) implemente edildi

### Router
- [x] `app_router.dart` → `RouteScreen` query parametrelerinden neighborhood/district/province alıyor
- [x] `app_router.dart` → `NeighborhoodDetailScreen` doğru `NeighborhoodStats` constructor

### Test
- [x] `test/score_engine_test.dart` → Doğru parametre isimleri ve API kullanımı

---

## 🔴 Siz Yapacaksınız (5 adım — 20 dakika)

### Adım 1 — .env dosyasını doldurun

`.env` dosyasını açın:
```
ANTHROPIC_API_KEY=sk-ant-api03-...
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

### Adım 2 — Firebase kurulumu (Android + iOS)

1. https://console.firebase.google.com → proje oluşturun
2. **Android**: "Android uygulaması ekle" → package: `com.example.sehir_ses`
   → `google-services.json` indirin → `android/app/` klasörüne koyun
3. **iOS**: "iOS uygulaması ekle" → bundle ID: `com.example.sehirSes`
   → `GoogleService-Info.plist` indirin → `ios/Runner/` klasörüne koyun
4. Firebase Console → Build → Cloud Messaging → etkinleştirin

### Adım 3 — Supabase migrations

Supabase Dashboard → SQL Editor'de sırayla:
```sql
-- Sırasıyla çalıştırın:
-- 1. supabase/migrations/001_initial_schema.sql
-- 2. supabase/migrations/002_extended_schema.sql
-- 3. supabase/seed/istanbul_seed.sql
-- 4. İlk snapshot:
SELECT record_daily_score_snapshot();
```

### Adım 4 — Edge Functions deploy

```bash
npm install -g supabase
supabase login
supabase functions deploy analyze-feedback
supabase functions deploy generate-report
supabase functions deploy recalculate-scores
```

Cron job (Supabase → Database → pg_cron):
```sql
SELECT cron.schedule('nightly-score-recalc', '0 2 * * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.edge_function_url') || '/recalculate-scores',
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := '{"province":"İstanbul"}'::jsonb
  )$$
);
```

### Adım 5 — İstanbul GeoJSON (harita renklendirme için)

overpass-turbo.eu'da:
```
[out:json];
relation["admin_level"="10"]["name"~"mahalle"]["addr:city"="İstanbul"];
out geom;
```
İndirilen dosyayı `assets/geojson/istanbul.geojson` olarak kaydedin.

---

## 🚀 Build

```bash
flutter pub get
flutter test          # Testleri çalıştır
flutter run           # Debug
flutter build apk --release   # Android
flutter build ios --release   # iOS
```

---

## ⚠️ Production Checklist

- [ ] `.env` dosyasındaki tüm key'ler gerçek değerlerle dolduruldu
- [ ] `google-services.json` `android/app/` klasöründe
- [ ] `GoogleService-Info.plist` `ios/Runner/` klasöründe
- [ ] Supabase SQL migrations çalıştırıldı
- [ ] Edge functions deploy edildi
- [ ] Supabase RLS (Row Level Security) açık
- [ ] Cron job kuruldu
- [ ] Test komutları geçiyor: `flutter test`
- [ ] Release build test edildi gerçek cihazda

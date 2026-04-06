-- ============================================================
-- ŞehirSes — İstanbul Pilot Seed Verisi
-- 8 İlçe × ~3 Mahalle + Her Mahalleye Popüler Mekanlar
-- Faz 1 başlangıç verisi: sıfır içerikle soğuk start olmasın
-- ============================================================

-- ─── MAHALLE SKOR BAŞLANGIÇ VERİLERİ ─────────────────────────
-- Kaynak: Editöryal başlangıç + açık veri tahminleri
INSERT INTO public.neighborhood_scores (
  province, district, neighborhood,
  overall_score, total_feedbacks,
  score_cleaning, score_road, score_security, score_park, score_transport, score_social,
  tourist_interest, social_life, user_satisfaction, accessibility, safety, venue_density,
  trend_direction, walk_score, has_metro_access, area_sq_km
) VALUES

-- ── KADIKÖY ──────────────────────────────────────────────────
('İstanbul', 'Kadıköy', 'Moda',
  84.5, 0, 88, 78, 82, 86, 90, 88,
  88, 92, 82, 95, 80, 90, 'rising', 92, TRUE, 1.2),

('İstanbul', 'Kadıköy', 'Fenerbahçe',
  79.2, 0, 82, 75, 84, 90, 85, 72,
  75, 72, 79, 87, 82, 70, 'stable', 85, TRUE, 1.8),

('İstanbul', 'Kadıköy', 'Caferağa',
  76.8, 0, 78, 72, 78, 72, 88, 84,
  78, 88, 76, 93, 76, 88, 'rising', 88, TRUE, 0.9),

-- ── BEŞİKTAŞ ─────────────────────────────────────────────────
('İstanbul', 'Beşiktaş', 'Nişantaşı',
  85.3, 0, 86, 80, 86, 75, 88, 92,
  82, 94, 84, 91, 84, 95, 'stable', 90, TRUE, 1.1),

('İstanbul', 'Beşiktaş', 'Bebek',
  88.7, 0, 90, 84, 90, 88, 82, 88,
  96, 88, 88, 85, 90, 82, 'rising', 82, FALSE, 2.1),

('İstanbul', 'Beşiktaş', 'Ortaköy',
  82.1, 0, 84, 76, 80, 80, 86, 90,
  94, 90, 80, 88, 78, 88, 'stable', 80, TRUE, 0.8),

-- ── ŞİŞLİ ────────────────────────────────────────────────────
('İstanbul', 'Şişli', 'Teşvikiye',
  81.4, 0, 84, 78, 84, 72, 88, 88,
  80, 88, 81, 93, 82, 92, 'stable', 88, TRUE, 0.7),

('İstanbul', 'Şişli', 'Bomonti',
  75.6, 0, 78, 72, 76, 68, 82, 82,
  70, 85, 75, 88, 74, 88, 'rising', 83, TRUE, 0.6),

('İstanbul', 'Şişli', 'Çukurcuma',
  72.3, 0, 74, 66, 74, 66, 80, 80,
  82, 82, 72, 84, 72, 80, 'stable', 78, TRUE, 0.4),

-- ── BEYOĞLU ──────────────────────────────────────────────────
('İstanbul', 'Beyoğlu', 'Cihangir',
  80.9, 0, 80, 70, 76, 80, 88, 90,
  92, 92, 80, 91, 74, 90, 'stable', 88, TRUE, 0.5),

('İstanbul', 'Beyoğlu', 'Galata',
  78.4, 0, 76, 68, 74, 68, 88, 88,
  96, 88, 78, 90, 72, 88, 'rising', 82, TRUE, 0.4),

('İstanbul', 'Beyoğlu', 'Karaköy',
  77.2, 0, 78, 72, 72, 62, 90, 86,
  88, 86, 77, 94, 70, 86, 'rising', 84, TRUE, 0.3),

-- ── ÜSKÜDAR ──────────────────────────────────────────────────
('İstanbul', 'Üsküdar', 'Çengelköy',
  82.6, 0, 84, 80, 86, 86, 80, 78,
  86, 76, 82, 80, 84, 72, 'stable', 75, FALSE, 3.2),

('İstanbul', 'Üsküdar', 'Kuzguncuk',
  79.8, 0, 82, 78, 84, 84, 76, 76,
  88, 76, 79, 78, 82, 70, 'rising', 72, FALSE, 1.4),

('İstanbul', 'Üsküdar', 'Bağlarbaşı',
  68.4, 0, 70, 64, 72, 72, 74, 68,
  60, 68, 68, 76, 70, 64, 'stable', 70, FALSE, 2.1),

-- ── FATİH ─────────────────────────────────────────────────────
('İstanbul', 'Fatih', 'Sultanahmet',
  86.2, 0, 88, 76, 82, 78, 88, 84,
  100, 80, 84, 90, 78, 82, 'stable', 85, TRUE, 1.6),

('İstanbul', 'Fatih', 'Balat',
  74.5, 0, 72, 64, 72, 72, 82, 78,
  90, 78, 74, 86, 70, 76, 'rising', 79, TRUE, 0.9),

('İstanbul', 'Fatih', 'Fener',
  71.8, 0, 70, 62, 70, 68, 80, 74,
  82, 74, 71, 82, 68, 72, 'rising', 76, TRUE, 0.7),

-- ── MALTEPE ──────────────────────────────────────────────────
('İstanbul', 'Maltepe', 'Bağlarbaşı',
  65.2, 0, 68, 60, 68, 66, 72, 62,
  50, 62, 65, 74, 66, 58, 'stable', 67, TRUE, 2.8),

('İstanbul', 'Maltepe', 'Cevizli',
  61.4, 0, 64, 56, 64, 60, 70, 58,
  45, 58, 61, 72, 62, 54, 'falling', 64, TRUE, 3.1),

-- ── PENDİK ───────────────────────────────────────────────────
('İstanbul', 'Pendik', 'Kurtköy',
  58.7, 0, 60, 54, 60, 56, 68, 54,
  40, 54, 58, 70, 58, 50, 'stable', 60, FALSE, 4.2),

('İstanbul', 'Pendik', 'Sapanbağları',
  54.3, 0, 56, 50, 56, 52, 62, 50,
  35, 50, 54, 65, 54, 46, 'falling', 56, FALSE, 3.8),

-- ── SARIYER ──────────────────────────────────────────────────
('İstanbul', 'Sarıyer', 'Tarabya',
  80.4, 0, 82, 76, 82, 86, 74, 76,
  88, 74, 80, 75, 80, 68, 'stable', 70, FALSE, 4.5),

('İstanbul', 'Sarıyer', 'Yeniköy',
  83.1, 0, 84, 80, 86, 88, 76, 78,
  92, 76, 83, 76, 84, 70, 'rising', 72, FALSE, 5.2),

('İstanbul', 'Sarıyer', 'Emirgan',
  81.7, 0, 84, 78, 84, 92, 72, 72,
  90, 70, 81, 73, 82, 65, 'stable', 68, FALSE, 3.8)

ON CONFLICT (province, district, neighborhood) DO NOTHING;

-- ─── POPÜLER MEKANLAR ─────────────────────────────────────────
INSERT INTO public.places (
  name, province, district, neighborhood, category,
  latitude, longitude, address, description,
  is_tourist_spot, is_verified, monthly_visits
) VALUES

-- Moda, Kadıköy
('Moda Sahili', 'İstanbul', 'Kadıköy', 'Moda', 'nature',
  40.9803, 29.0245, 'Moda Caddesi, Kadıköy',
  'İstanbul''un en güzel sahil yürüyüş yolu. Gün batımı için mükemmel.',
  TRUE, TRUE, 8500),

('Moda Çay Bahçesi', 'İstanbul', 'Kadıköy', 'Moda', 'cafe',
  40.9812, 29.0238, 'Moda Caddesi 12, Kadıköy',
  'Deniz manzaralı tarihi çay bahçesi.',
  FALSE, TRUE, 3200),

('Moda Market', 'İstanbul', 'Kadıköy', 'Moda', 'market',
  40.9798, 29.0251, 'Moda Caddesi, Kadıköy',
  'Organik ürünler ve yerel üreticiler.',
  FALSE, TRUE, 2100),

-- Bebek, Beşiktaş
('Bebek Sahili', 'İstanbul', 'Beşiktaş', 'Bebek', 'nature',
  41.0773, 29.0437, 'Bebek Sahil Yolu, Beşiktaş',
  'Boğaz manzaralı ikonik sahil yolu.',
  TRUE, TRUE, 12000),

('Bebek Kahvesi', 'İstanbul', 'Beşiktaş', 'Bebek', 'cafe',
  41.0768, 29.0430, 'Cevdetpaşa Caddesi, Bebek',
  '1950''lerden beri hizmet veren tarihi kafe.',
  TRUE, TRUE, 5400),

('Bebek Parkı', 'İstanbul', 'Beşiktaş', 'Bebek', 'park',
  41.0781, 29.0442, 'Bebek, Beşiktaş',
  'Boğaz kenarında geniş yeşil alan.',
  FALSE, TRUE, 4200),

-- Cihangir, Beyoğlu
('Cihangir Camii', 'İstanbul', 'Beyoğlu', 'Cihangir', 'monument',
  41.0302, 28.9854, 'Cihangir Caddesi, Beyoğlu',
  '16. yüzyıldan kalma tarihi cami, Boğaz manzaralı.',
  TRUE, TRUE, 3800),

('Latte Art Cafe Cihangir', 'İstanbul', 'Beyoğlu', 'Cihangir', 'cafe',
  41.0295, 28.9848, 'Akarsu Sokak, Cihangir',
  'Semtin bohemik atmosferine uygun sanatçı kafesi.',
  FALSE, TRUE, 2800),

-- Galata, Beyoğlu
('Galata Kulesi', 'İstanbul', 'Beyoğlu', 'Galata', 'monument',
  41.0256, 28.9744, 'Galata Kulesi Sk., Beyoğlu',
  'İstanbul''un simgesi, 528 yıllık kulüben muhteşem panorama.',
  TRUE, TRUE, 18000),

('Galata Köprüsü', 'İstanbul', 'Beyoğlu', 'Galata', 'monument',
  41.0175, 28.9736, 'Galata Köprüsü, Eminönü',
  'Tarihi köprü, oltacılar ve manzara için ikonik nokta.',
  TRUE, TRUE, 22000),

-- Sultanahmet, Fatih
('Ayasofya', 'İstanbul', 'Fatih', 'Sultanahmet', 'museum',
  41.0086, 28.9802, 'Sultanahmet Mh., Fatih',
  'Türkiye''nin en ziyaret edilen tarihi yapısı.',
  TRUE, TRUE, 55000),

('Topkapı Sarayı', 'İstanbul', 'Fatih', 'Sultanahmet', 'museum',
  41.0115, 28.9834, 'Babıhümayun Caddesi, Fatih',
  'Osmanlı İmparatorluğu''nun 400 yıllık yönetim merkezi.',
  TRUE, TRUE, 42000),

('Sultanahmet Camii (Mavi Cami)', 'İstanbul', 'Fatih', 'Sultanahmet', 'monument',
  41.0054, 28.9768, 'Atmeydanı Caddesi, Fatih',
  'Altı minareli dünyaca ünlü Osmanlı camii.',
  TRUE, TRUE, 38000),

-- Balat, Fatih
('Balat Kapı', 'İstanbul', 'Fatih', 'Balat', 'monument',
  41.0265, 28.9504, 'Vodina Caddesi, Balat',
  'Bizans surlarının tarihi kapısı.',
  TRUE, TRUE, 4200),

('Balat Kahvesi', 'İstanbul', 'Fatih', 'Balat', 'cafe',
  41.0248, 28.9512, 'Kürkçü Çeşme Sk., Balat',
  'Rengarenk Balat sokaklarında nostaljik kafe deneyimi.',
  FALSE, TRUE, 3100),

-- Çengelköy, Üsküdar
('Çengelköy Sahili', 'İstanbul', 'Üsküdar', 'Çengelköy', 'nature',
  41.0553, 29.0612, 'Çengelköy İskelesi, Üsküdar',
  'Boğaz manzarası ve serin havasıyla sakin bir sahil.',
  TRUE, TRUE, 4800),

-- Kuzguncuk, Üsküdar
('Kuzguncuk Sahili', 'İstanbul', 'Üsküdar', 'Kuzguncuk', 'nature',
  41.0440, 29.0555, 'Kuzguncuk Sahil, Üsküdar',
  'Ahşap evleriyle İstanbul''un en pitoresk sahil mahallesinden biri.',
  TRUE, TRUE, 5600),

-- Tarabya, Sarıyer
('Tarabya Koyu', 'İstanbul', 'Sarıyer', 'Tarabya', 'nature',
  41.1562, 29.0695, 'Tarabya Sahil, Sarıyer',
  'İstanbul''un en güzel doğal koylarından biri.',
  TRUE, TRUE, 6200),

-- Ortaköy, Beşiktaş
('Ortaköy Camii', 'İstanbul', 'Beşiktaş', 'Ortaköy', 'monument',
  41.0480, 29.0272, 'Meclis-i Mebusan Caddesi, Ortaköy',
  'Boğaz Köprüsü önünde Neobarok cami; ikonik fotoğraf noktası.',
  TRUE, TRUE, 14000),

('Ortaköy Meydanı', 'İstanbul', 'Beşiktaş', 'Ortaköy', 'market',
  41.0474, 29.0265, 'Ortaköy Meydanı, Beşiktaş',
  'Kumpir, saat ve el işi ürünleriyle ünlü meydan.',
  TRUE, TRUE, 10000);

-- ─── SKOR GEÇMİŞİ BAŞLANGIÇ (son 7 gün simülasyonu) ──────────
-- Trend analizinin çalışması için birkaç geçmiş kayıt ekle
INSERT INTO public.score_history
  (province, district, neighborhood, overall_score, review_count, recorded_at)
SELECT
  province, district, neighborhood,
  overall_score - (random() * 6 - 3),  -- ±3 puan varyasyon
  total_feedbacks,
  NOW() - INTERVAL '7 days'
FROM public.neighborhood_scores
WHERE province = 'İstanbul';

INSERT INTO public.score_history
  (province, district, neighborhood, overall_score, review_count, recorded_at)
SELECT
  province, district, neighborhood,
  overall_score - (random() * 4 - 2),
  total_feedbacks,
  NOW() - INTERVAL '3 days'
FROM public.neighborhood_scores
WHERE province = 'İstanbul';

-- ─── YORUM ÖRNEK VERİSİ ──────────────────────────────────────
-- Gerçek kullanıcı eklenince bu kısım kaldırılır.
-- Demo amaçlı: sistemin boş görünmemesi için.
DO $$
DECLARE
  demo_user_id UUID;
BEGIN
  -- Demo admin kullanıcı yoksa atla
  SELECT id INTO demo_user_id FROM public.users WHERE phone = '+905550000000' LIMIT 1;
  IF demo_user_id IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.feedbacks (user_id, province, district, neighborhood, category, rating, comment)
  VALUES
    (demo_user_id, 'İstanbul', 'Kadıköy', 'Moda', 'social',   5, 'Moda en yaşanabilir mahallelerin başında geliyor. Sahil yürüyüşleri muhteşem.'),
    (demo_user_id, 'İstanbul', 'Kadıköy', 'Moda', 'cleaning', 4, 'Temizlik genel olarak iyi ama sahil kıyısında çöpler birikebiliyor.'),
    (demo_user_id, 'İstanbul', 'Beşiktaş', 'Bebek', 'park',   5, 'Bebek sahili İstanbul''un en güzel noktalarından biri, parklar bakımlı.'),
    (demo_user_id, 'İstanbul', 'Beyoğlu', 'Galata', 'transport', 4, 'Metro ve tramvay erişimi çok iyi, her yere kolayca ulaşabiliyorsunuz.'),
    (demo_user_id, 'İstanbul', 'Fatih', 'Sultanahmet', 'road', 3, 'Tarihi dokuyu korumak güzel ama bazı sokaklar turizm yüzünden çok kalabalık.');
END;
$$;

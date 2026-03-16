-- ============================================================
-- ŞehirSes — Genişletilmiş Veritabanı Şeması (Migrasyon 002)
-- Mekanlar, Skor Geçmişi, Favoriler, Rotalar, Moderasyon
-- ============================================================

-- ─── YENİ ENUM'LAR ────────────────────────────────────────────
CREATE TYPE place_category AS ENUM (
  'cafe', 'restaurant', 'park', 'museum', 'monument',
  'market', 'bar', 'sports', 'shopping', 'health',
  'education', 'transport', 'hotel', 'entertainment', 'nature'
);

CREATE TYPE moderation_status AS ENUM ('pending', 'approved', 'rejected', 'flagged');
CREATE TYPE route_type AS ENUM (
  'quick_walk', 'coffee_and_walk', 'sunset', 'student_budget',
  'family_day', 'historic_tour', 'food_tour', 'night_out'
);

-- ─── MEKAN KATEGORİLERİ ───────────────────────────────────────
CREATE TABLE public.place_categories (
  id          SERIAL PRIMARY KEY,
  slug        place_category NOT NULL UNIQUE,
  label_tr    TEXT NOT NULL,
  icon_name   TEXT NOT NULL,  -- Flutter Icons enum key
  color_hex   TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── MEKANLAR ─────────────────────────────────────────────────
-- Her POI (Point of Interest) buraya girer.
CREATE TABLE public.places (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  province        TEXT NOT NULL,
  district        TEXT NOT NULL,
  neighborhood    TEXT NOT NULL,
  category        place_category NOT NULL,
  latitude        NUMERIC(9,6) NOT NULL,
  longitude       NUMERIC(9,6) NOT NULL,
  address         TEXT,
  description     TEXT,
  photo_url       TEXT,
  -- Aggregated stats (trigger ile güncellenir)
  avg_rating      NUMERIC(3,2) DEFAULT NULL,
  review_count    INTEGER NOT NULL DEFAULT 0,
  monthly_visits  INTEGER NOT NULL DEFAULT 0,  -- tahmini ziyaret
  -- Flags
  is_tourist_spot BOOLEAN NOT NULL DEFAULT FALSE,
  is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  -- Meta
  opening_hours   JSONB,   -- {"mon": "09:00-22:00", "sun": "10:00-20:00"}
  osm_id          TEXT,    -- OpenStreetMap referansı
  google_place_id TEXT,    -- Google Places referansı
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Coğrafi index (bbox sorguları için)
CREATE INDEX idx_places_geo        ON public.places (province, district, neighborhood);
CREATE INDEX idx_places_category   ON public.places (province, category);
CREATE INDEX idx_places_tourist    ON public.places (province, is_tourist_spot) WHERE is_tourist_spot = TRUE;
CREATE INDEX idx_places_fulltext   ON public.places USING gin(to_tsvector('turkish', name || ' ' || COALESCE(description, '')));

-- ─── MEKAN YORUMLARı ──────────────────────────────────────────
-- Genel feedback'ten ayrı: doğrudan bir mekan hakkında yorum
CREATE TABLE public.place_reviews (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  place_id     UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      TEXT CHECK (char_length(comment) <= 500),
  photo_urls   TEXT[] DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(place_id, user_id)  -- kullanıcı başına bir yorum
);

-- Mekan ortalama puanını trigger ile güncelle
CREATE OR REPLACE FUNCTION update_place_avg_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.places
  SET
    avg_rating   = (SELECT AVG(rating)   FROM public.place_reviews WHERE place_id = NEW.place_id),
    review_count = (SELECT COUNT(*)      FROM public.place_reviews WHERE place_id = NEW.place_id),
    updated_at   = NOW()
  WHERE id = NEW.place_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_place_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.place_reviews
  FOR EACH ROW EXECUTE FUNCTION update_place_avg_rating();

-- ─── SKOR GEÇMİŞİ ─────────────────────────────────────────────
-- Her gün gece yarısı anlık puan snapshot'ı kaydedilir.
-- "Bu mahalle son 30 günde yükseldi mi?" buradan hesaplanır.
CREATE TABLE public.score_history (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  province         TEXT NOT NULL,
  district         TEXT NOT NULL,
  neighborhood     TEXT NOT NULL,
  -- Alt skorlar
  overall_score    NUMERIC(5,2) NOT NULL,
  tourist_interest NUMERIC(5,2),
  social_life      NUMERIC(5,2),
  user_satisfaction NUMERIC(5,2),
  accessibility    NUMERIC(5,2),
  cleanliness      NUMERIC(5,2),
  safety           NUMERIC(5,2),
  venue_density    NUMERIC(5,2),
  -- Meta
  review_count     INTEGER NOT NULL DEFAULT 0,
  place_count      INTEGER NOT NULL DEFAULT 0,
  trend_delta      NUMERIC(4,2) DEFAULT 0,
  recorded_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_score_history_lookup ON public.score_history (province, district, neighborhood, recorded_at DESC);

-- ─── GENİŞLETİLMİŞ MAHALLE SKORLARI ──────────────────────────
-- Mevcut neighborhood_scores tablosuna yeni kolonlar ekle
ALTER TABLE public.neighborhood_scores
  ADD COLUMN IF NOT EXISTS tourist_interest    NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS social_life         NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS user_satisfaction   NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accessibility       NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS safety              NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS venue_density       NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS trend_delta         NUMERIC(4,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS trend_direction     TEXT DEFAULT 'stable',  -- 'rising' | 'falling' | 'stable'
  ADD COLUMN IF NOT EXISTS place_count         INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS area_sq_km          NUMERIC(8,4) DEFAULT 1.0,
  ADD COLUMN IF NOT EXISTS has_metro_access    BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS walk_score          NUMERIC(5,2) DEFAULT 50.0;

-- ─── FAVORİLER ────────────────────────────────────────────────
CREATE TABLE public.favorites (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- Ya mahalle favori ya mekan favori
  neighborhood TEXT,
  district     TEXT,
  province     TEXT,
  place_id     UUID REFERENCES public.places(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- En az biri dolu olmalı
  CONSTRAINT chk_favorite_target CHECK (
    (neighborhood IS NOT NULL) OR (place_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_favorites_neighborhood
  ON public.favorites (user_id, neighborhood, district, province)
  WHERE neighborhood IS NOT NULL;

CREATE UNIQUE INDEX idx_favorites_place
  ON public.favorites (user_id, place_id)
  WHERE place_id IS NOT NULL;

-- ─── ROTALAR (İTİNERARY) ──────────────────────────────────────
CREATE TABLE public.itineraries (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  neighborhood TEXT NOT NULL,
  province     TEXT NOT NULL,
  route_type   route_type,
  stops        JSONB NOT NULL DEFAULT '[]',  -- [{place_id, place_name, order, suggested_minutes}]
  ai_summary   TEXT,
  is_public    BOOLEAN NOT NULL DEFAULT FALSE,
  view_count   INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_itineraries_user     ON public.itineraries (user_id);
CREATE INDEX idx_itineraries_public   ON public.itineraries (neighborhood, province) WHERE is_public = TRUE;

-- ─── MODERASYon KUYRUĞU ──────────────────────────────────────
CREATE TABLE public.moderation_queue (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id    UUID REFERENCES public.feedbacks(id) ON DELETE CASCADE,
  province     TEXT NOT NULL,
  neighborhood TEXT NOT NULL,
  content      TEXT NOT NULL,       -- kopyalanmış yorum metni (silince de görünsün)
  -- AI analizi
  ai_reason    TEXT,                -- neden işaretlendi
  spam_score   NUMERIC(3,2),        -- 0-1 arası (1 = kesinlikle spam)
  toxicity_score NUMERIC(3,2),
  -- Moderatör
  status       moderation_status NOT NULL DEFAULT 'pending',
  admin_note   TEXT,
  resolved_by  UUID REFERENCES public.users(id),
  resolved_at  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_moderation_pending ON public.moderation_queue (province, status, spam_score DESC)
  WHERE status = 'pending';

-- ─── KULLANICI RAPORLARI ──────────────────────────────────────
-- Kullanıcı, bir yorumu şikayet edebilir
CREATE TABLE public.reports (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES public.users(id),
  review_id   UUID NOT NULL REFERENCES public.feedbacks(id) ON DELETE CASCADE,
  reason      TEXT NOT NULL,  -- 'spam' | 'offensive' | 'incorrect' | 'other'
  note        TEXT,
  is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(reporter_id, review_id)  -- kişi başına bir rapor
);

-- ─── BİLDİRİMLER ─────────────────────────────────────────────
CREATE TABLE public.notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES public.users(id) ON DELETE CASCADE,  -- NULL ise tüm kullanıcılar
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  data        JSONB DEFAULT '{}',
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  sent_via_fcm BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications (user_id, is_read, created_at DESC);

-- ─── DENETİM LOGU ────────────────────────────────────────────
-- Admin işlemlerini izle
CREATE TABLE public.audit_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id    UUID REFERENCES public.users(id),
  action      TEXT NOT NULL,   -- 'approve_review' | 'ban_user' | 'delete_place' ...
  target_type TEXT,            -- 'review' | 'user' | 'place'
  target_id   UUID,
  metadata    JSONB DEFAULT '{}',
  ip_address  INET,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── ROW LEVEL SECURITY ──────────────────────────────────────
ALTER TABLE public.favorites    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itineraries  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Kullanıcı yalnızca kendi favorilerini görür/yönetir
CREATE POLICY favorites_own ON public.favorites
  USING (user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- Kendi rotaları + herkese açık rotalar
CREATE POLICY itineraries_own ON public.itineraries
  USING (user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid()) OR is_public = TRUE);

CREATE POLICY itineraries_insert ON public.itineraries
  WITH CHECK (user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid()))
  AS PERMISSIVE FOR INSERT TO authenticated;

-- Kendi bildirimleri
CREATE POLICY notifications_own ON public.notifications
  USING (user_id IS NULL OR user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- ─── ANLIK SKOR GÜNCELLEME FONKSİYONU (geliştirilmiş) ─────────
-- Feedback eklenince hem simple avg hem trend hesapla
CREATE OR REPLACE FUNCTION update_neighborhood_score_v2()
RETURNS TRIGGER AS $$
DECLARE
  v_total          INTEGER;
  v_overall        NUMERIC;
  v_cleaning       NUMERIC;
  v_road           NUMERIC;
  v_security       NUMERIC;
  v_park           NUMERIC;
  v_transport      NUMERIC;
  v_social         NUMERIC;
  v_recent_avg     NUMERIC;
  v_previous_avg   NUMERIC;
  v_trend          NUMERIC;
  v_trend_dir      TEXT;
BEGIN
  -- Temel kategori ortalamaları (1-5 → 0-100)
  SELECT
    COUNT(*),
    AVG(CASE WHEN category = 'cleaning'  THEN rating END) * 20,
    AVG(CASE WHEN category = 'road'      THEN rating END) * 20,
    AVG(CASE WHEN category = 'security'  THEN rating END) * 20,
    AVG(CASE WHEN category = 'park'      THEN rating END) * 20,
    AVG(CASE WHEN category = 'transport' THEN rating END) * 20,
    AVG(CASE WHEN category = 'social'    THEN rating END) * 20,
    AVG(rating) * 20
  INTO v_total, v_cleaning, v_road, v_security, v_park, v_transport, v_social, v_overall
  FROM public.feedbacks
  WHERE
    province     = NEW.province AND
    district     = NEW.district AND
    neighborhood = NEW.neighborhood AND
    is_hidden    = FALSE;

  -- Trend hesapla: son 30 gün vs önceki 30 gün
  SELECT AVG(rating) * 20 INTO v_recent_avg
  FROM public.feedbacks
  WHERE province = NEW.province AND district = NEW.district AND neighborhood = NEW.neighborhood
    AND created_at >= NOW() - INTERVAL '30 days' AND is_hidden = FALSE;

  SELECT AVG(rating) * 20 INTO v_previous_avg
  FROM public.feedbacks
  WHERE province = NEW.province AND district = NEW.district AND neighborhood = NEW.neighborhood
    AND created_at BETWEEN NOW() - INTERVAL '60 days' AND NOW() - INTERVAL '30 days'
    AND is_hidden = FALSE;

  v_trend := COALESCE(v_recent_avg, 50) - COALESCE(v_previous_avg, 50);
  v_trend_dir := CASE
    WHEN v_trend > 2  THEN 'rising'
    WHEN v_trend < -2 THEN 'falling'
    ELSE 'stable'
  END;

  -- UPSERT neighborhood_scores
  INSERT INTO public.neighborhood_scores (
    province, district, neighborhood,
    overall_score, total_feedbacks,
    score_cleaning, score_road, score_security,
    score_park, score_transport, score_social,
    trend_delta, trend_direction,
    last_updated
  ) VALUES (
    NEW.province, NEW.district, NEW.neighborhood,
    COALESCE(v_overall, 0), v_total,
    COALESCE(v_cleaning, 0),   COALESCE(v_road, 0),      COALESCE(v_security, 0),
    COALESCE(v_park, 0),       COALESCE(v_transport, 0),  COALESCE(v_social, 0),
    COALESCE(v_trend, 0), v_trend_dir, NOW()
  )
  ON CONFLICT (province, district, neighborhood)
  DO UPDATE SET
    overall_score    = EXCLUDED.overall_score,
    total_feedbacks  = EXCLUDED.total_feedbacks,
    score_cleaning   = EXCLUDED.score_cleaning,
    score_road       = EXCLUDED.score_road,
    score_security   = EXCLUDED.score_security,
    score_park       = EXCLUDED.score_park,
    score_transport  = EXCLUDED.score_transport,
    score_social     = EXCLUDED.score_social,
    trend_delta      = EXCLUDED.trend_delta,
    trend_direction  = EXCLUDED.trend_direction,
    last_updated     = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eski trigger'ı değiştir
DROP TRIGGER IF EXISTS trg_update_neighborhood_score ON public.feedbacks;
CREATE TRIGGER trg_update_neighborhood_score_v2
  AFTER INSERT OR UPDATE ON public.feedbacks
  FOR EACH ROW EXECUTE FUNCTION update_neighborhood_score_v2();

-- ─── GÜNLÜK SKOR SNAPSHOT FONKSİYONU ────────────────────────
-- Cron job ile her gün gece çağrılır: SELECT record_daily_score_snapshot();
CREATE OR REPLACE FUNCTION record_daily_score_snapshot()
RETURNS void AS $$
BEGIN
  INSERT INTO public.score_history (
    province, district, neighborhood,
    overall_score, review_count, recorded_at
  )
  SELECT
    province, district, neighborhood,
    overall_score, total_feedbacks, NOW()
  FROM public.neighborhood_scores;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supabase'de pg_cron ile her gece 00:00 çalıştır:
-- SELECT cron.schedule('daily-score-snapshot', '0 0 * * *', 'SELECT record_daily_score_snapshot()');

-- ─── MEKAN KATEGORİ SEED VERİSİ ──────────────────────────────
INSERT INTO public.place_categories (slug, label_tr, icon_name, color_hex) VALUES
  ('cafe',          'Kafe',           'local_cafe',     '#8D6E63'),
  ('restaurant',    'Restoran',       'restaurant',     '#FF7043'),
  ('park',          'Park',           'park',           '#43A047'),
  ('museum',        'Müze',           'museum',         '#5C6BC0'),
  ('monument',      'Tarihi Yapı',    'account_balance','#7E57C2'),
  ('market',        'Pazar',          'storefront',     '#FFB300'),
  ('bar',           'Bar',            'nightlife',      '#1565C0'),
  ('sports',        'Spor',           'sports_soccer',  '#00897B'),
  ('shopping',      'Alışveriş',      'shopping_bag',   '#E91E63'),
  ('health',        'Sağlık',         'local_hospital', '#E53935'),
  ('education',     'Eğitim',         'school',         '#039BE5'),
  ('transport',     'Ulaşım',         'directions_bus', '#546E7A'),
  ('hotel',         'Konaklama',      'hotel',          '#00ACC1'),
  ('entertainment', 'Eğlence',        'theater_comedy', '#AB47BC'),
  ('nature',        'Doğa/Manzara',   'landscape',      '#558B2F')
ON CONFLICT (slug) DO NOTHING;

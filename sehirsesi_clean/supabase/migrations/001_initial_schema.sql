-- ============================================================
-- ŞehirSes — Supabase Veritabanı Şeması
-- ============================================================

-- UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Metin araması için

-- ─── ENUM TİPLERİ ────────────────────────────────────────────
CREATE TYPE feedback_category AS ENUM (
  'cleaning',
  'road',
  'security',
  'park',
  'transport',
  'social'
);

CREATE TYPE sentiment_type AS ENUM ('positive', 'negative', 'neutral');
CREATE TYPE urgency_level AS ENUM ('low', 'medium', 'high');
CREATE TYPE user_role AS ENUM ('citizen', 'municipality', 'admin');

-- ─── KULLANICILAR TABLOSU ────────────────────────────────────
CREATE TABLE public.users (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id         UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  phone           TEXT UNIQUE NOT NULL,
  tc_hash         TEXT NOT NULL,          -- TC Kimlik hash'i (SHA-256)
  full_name       TEXT,
  birth_year      SMALLINT,
  province        TEXT NOT NULL DEFAULT 'Gaziantep',
  district        TEXT NOT NULL,
  neighborhood    TEXT NOT NULL,
  role            user_role NOT NULL DEFAULT 'citizen',
  municipality_id UUID,                   -- Belediye kullanıcısı ise
  is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── BELEDİYELER TABLOSU ─────────────────────────────────────
CREATE TABLE public.municipalities (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         TEXT NOT NULL,             -- Gaziantep Büyükşehir Belediyesi
  province     TEXT NOT NULL,
  district     TEXT,                      -- NULL ise il geneli
  logo_url     TEXT,
  contact_email TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── GERİ BİLDİRİMLER TABLOSU ────────────────────────────────
CREATE TABLE public.feedbacks (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  province        TEXT NOT NULL,
  district        TEXT NOT NULL,
  neighborhood    TEXT NOT NULL,
  category        feedback_category NOT NULL,
  rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment         TEXT NOT NULL CHECK (char_length(comment) BETWEEN 10 AND 500),
  photo_urls      TEXT[] DEFAULT '{}',
  -- AI Analizi
  ai_sentiment    sentiment_type,
  ai_summary      TEXT,
  ai_urgency      urgency_level,
  ai_processed    BOOLEAN NOT NULL DEFAULT FALSE,
  -- Meta
  is_anonymous    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── MAHALLe SKORLARI (Materyalize View benzeri) ──────────────
CREATE TABLE public.neighborhood_scores (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  province          TEXT NOT NULL,
  district          TEXT NOT NULL,
  neighborhood      TEXT NOT NULL,
  overall_score     NUMERIC(5,2) NOT NULL DEFAULT 0,
  total_feedbacks   INTEGER NOT NULL DEFAULT 0,
  -- Kategori skorları
  score_cleaning    NUMERIC(5,2) DEFAULT 0,
  score_road        NUMERIC(5,2) DEFAULT 0,
  score_security    NUMERIC(5,2) DEFAULT 0,
  score_park        NUMERIC(5,2) DEFAULT 0,
  score_transport   NUMERIC(5,2) DEFAULT 0,
  score_social      NUMERIC(5,2) DEFAULT 0,
  -- AI raporu
  ai_report         TEXT,
  ai_report_at      TIMESTAMPTZ,
  last_updated      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(province, district, neighborhood)
);

-- ─── BELEDİYE RAPORLARI ──────────────────────────────────────
CREATE TABLE public.municipality_reports (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  municipality_id   UUID NOT NULL REFERENCES public.municipalities(id),
  province          TEXT NOT NULL,
  district          TEXT,
  overall_score     NUMERIC(5,2) NOT NULL,
  total_feedbacks   INTEGER NOT NULL,
  critical_issues   TEXT[] DEFAULT '{}',
  recommendations   TEXT[] DEFAULT '{}',
  ai_summary        TEXT,
  period_start      DATE NOT NULL,
  period_end        DATE NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── BİLDİRİMLER ─────────────────────────────────────────────
CREATE TABLE public.notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES public.users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  data        JSONB DEFAULT '{}',
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- İNDEKSLER
-- ============================================================
CREATE INDEX idx_feedbacks_location ON public.feedbacks(province, district, neighborhood);
CREATE INDEX idx_feedbacks_category ON public.feedbacks(category);
CREATE INDEX idx_feedbacks_created ON public.feedbacks(created_at DESC);
CREATE INDEX idx_feedbacks_user ON public.feedbacks(user_id);
CREATE INDEX idx_neighborhood_scores_location ON public.neighborhood_scores(province, district);
CREATE INDEX idx_users_phone ON public.users(phone);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.neighborhood_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.municipality_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- USERS politikaları
CREATE POLICY "Kullanıcı kendi profilini görebilir"
  ON public.users FOR SELECT
  USING (auth.uid() = auth_id);

CREATE POLICY "Kullanıcı kendi profilini güncelleyebilir"
  ON public.users FOR UPDATE
  USING (auth.uid() = auth_id);

CREATE POLICY "Belediye personeli tüm kullanıcıları görebilir"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role IN ('municipality', 'admin')
    )
  );

-- FEEDBACKS politikaları
CREATE POLICY "Herkes geri bildirim okuyabilir (anonim hariç)"
  ON public.feedbacks FOR SELECT
  USING (
    is_anonymous = FALSE OR
    user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

CREATE POLICY "Giriş yapmış kullanıcı geri bildirim ekleyebilir"
  ON public.feedbacks FOR INSERT
  WITH CHECK (
    user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

CREATE POLICY "Kullanıcı kendi geri bildirimini silebilir"
  ON public.feedbacks FOR DELETE
  USING (
    user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- NEIGHBORHOOD SCORES - Herkes okuyabilir
CREATE POLICY "Mahalle skorları herkese açık"
  ON public.neighborhood_scores FOR SELECT
  USING (true);

-- MUNICIPALITY REPORTS - Sadece belediye
CREATE POLICY "Belediye raporları sadece yetkililere"
  ON public.municipality_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = auth.uid() AND u.role IN ('municipality', 'admin')
    )
  );

-- NOTIFICATIONS
CREATE POLICY "Kullanıcı kendi bildirimlerini görür"
  ON public.notifications FOR SELECT
  USING (
    user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

CREATE POLICY "Kullanıcı bildirimlerini okundu yapabilir"
  ON public.notifications FOR UPDATE
  USING (
    user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- ============================================================
-- FONKSİYONLAR & TRİGGERLAR
-- ============================================================

-- Mahalle skorunu otomatik güncelle
CREATE OR REPLACE FUNCTION update_neighborhood_score()
RETURNS TRIGGER AS $$
DECLARE
  v_overall     NUMERIC;
  v_cleaning    NUMERIC;
  v_road        NUMERIC;
  v_security    NUMERIC;
  v_park        NUMERIC;
  v_transport   NUMERIC;
  v_social      NUMERIC;
  v_total       INTEGER;
BEGIN
  -- Hesapla: 1-5 puan → 0-100 skora çevir
  SELECT
    COUNT(*),
    AVG(CASE WHEN category = 'cleaning'  THEN (rating - 1) * 25.0 END),
    AVG(CASE WHEN category = 'road'      THEN (rating - 1) * 25.0 END),
    AVG(CASE WHEN category = 'security'  THEN (rating - 1) * 25.0 END),
    AVG(CASE WHEN category = 'park'      THEN (rating - 1) * 25.0 END),
    AVG(CASE WHEN category = 'transport' THEN (rating - 1) * 25.0 END),
    AVG(CASE WHEN category = 'social'    THEN (rating - 1) * 25.0 END),
    AVG((rating - 1) * 25.0)
  INTO v_total, v_cleaning, v_road, v_security, v_park, v_transport, v_social, v_overall
  FROM public.feedbacks
  WHERE
    province     = NEW.province AND
    district     = NEW.district AND
    neighborhood = NEW.neighborhood;

  -- UPSERT
  INSERT INTO public.neighborhood_scores (
    province, district, neighborhood,
    overall_score, total_feedbacks,
    score_cleaning, score_road, score_security,
    score_park, score_transport, score_social,
    last_updated
  ) VALUES (
    NEW.province, NEW.district, NEW.neighborhood,
    COALESCE(v_overall, 0),   v_total,
    COALESCE(v_cleaning, 0),  COALESCE(v_road, 0),   COALESCE(v_security, 0),
    COALESCE(v_park, 0),      COALESCE(v_transport, 0), COALESCE(v_social, 0),
    NOW()
  )
  ON CONFLICT (province, district, neighborhood)
  DO UPDATE SET
    overall_score   = EXCLUDED.overall_score,
    total_feedbacks = EXCLUDED.total_feedbacks,
    score_cleaning  = EXCLUDED.score_cleaning,
    score_road      = EXCLUDED.score_road,
    score_security  = EXCLUDED.score_security,
    score_park      = EXCLUDED.score_park,
    score_transport = EXCLUDED.score_transport,
    score_social    = EXCLUDED.score_social,
    last_updated    = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: feedback eklenince skoru güncelle
CREATE TRIGGER trg_update_neighborhood_score
  AFTER INSERT OR UPDATE ON public.feedbacks
  FOR EACH ROW
  EXECUTE FUNCTION update_neighborhood_score();

-- Updated_at otomatik güncelle
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auth kullanıcısı oluşununca otomatik profil oluştur
CREATE OR REPLACE FUNCTION handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (auth_id, phone, tc_hash, province, district, neighborhood)
  VALUES (
    NEW.id,
    NEW.phone,
    COALESCE(NEW.raw_user_meta_data->>'tc_hash', ''),
    COALESCE(NEW.raw_user_meta_data->>'province', 'Gaziantep'),
    COALESCE(NEW.raw_user_meta_data->>'district', ''),
    COALESCE(NEW.raw_user_meta_data->>'neighborhood', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_auth_user();

-- ============================================================
-- ÖRNEK VERİ (Demo)
-- ============================================================
INSERT INTO public.municipalities (name, province, district) VALUES
  ('Gaziantep Büyükşehir Belediyesi', 'Gaziantep', NULL),
  ('Şahinbey Belediyesi', 'Gaziantep', 'Şahinbey'),
  ('Şehitkamil Belediyesi', 'Gaziantep', 'Şehitkamil');

-- Demo mahalle skorları
INSERT INTO public.neighborhood_scores
  (province, district, neighborhood, overall_score, total_feedbacks,
   score_cleaning, score_road, score_security, score_park, score_transport, score_social)
VALUES
  ('Gaziantep', 'Şahinbey', 'Akkent',       72.5, 143, 75, 65, 80, 68, 70, 77),
  ('Gaziantep', 'Şahinbey', 'Bağlarbaşı',   58.3, 98,  60, 52, 65, 55, 58, 60),
  ('Gaziantep', 'Şahinbey', 'Gazikent',     84.1, 210, 88, 82, 90, 79, 83, 85),
  ('Gaziantep', 'Şahinbey', 'İncilipınar',  41.2, 67,  45, 35, 48, 38, 42, 39),
  ('Gaziantep', 'Şahinbey', 'Karataş',      66.8, 112, 70, 60, 72, 65, 67, 68),
  ('Gaziantep', 'Şahinbey', 'Mücahitler',   77.4, 189, 80, 74, 82, 72, 78, 79),
  ('Gaziantep', 'Şahinbey', 'Onur',         35.6, 54,  38, 30, 40, 33, 36, 35),
  ('Gaziantep', 'Şahinbey', 'Sakarya',      62.9, 88,  65, 58, 68, 60, 63, 63),
  ('Gaziantep', 'Şahinbey', 'Sultanbey',    79.2, 167, 82, 76, 85, 74, 80, 80),
  ('Gaziantep', 'Şahinbey', 'Törehan',      51.7, 72,  54, 46, 58, 49, 52, 51);

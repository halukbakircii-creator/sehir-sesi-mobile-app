// supabase/functions/recalculate-scores/index.ts
// ŞehirSes — Gece Skor Yeniden Hesaplama Edge Function
//
// Çağrım: cron job veya admin paneli "Skorları Güncelle" butonu
// POST /functions/v1/recalculate-scores  { province?: string }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL      = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── Ağırlıklar (score_engine.dart ile senkron tut) ─────────────
const W = {
  touristInterest:  0.20,
  socialLife:       0.20,
  userSatisfaction: 0.20,
  accessibility:    0.10,
  cleanliness:      0.10,
  safety:           0.15,
  venueDensity:     0.05,
};

const clamp = (v: number) => Math.max(0, Math.min(100, v));

// ── Alt skor hesaplayıcılar ────────────────────────────────────
function calcUserSatisfaction(avgRating: number, count: number): number {
  const prior = 3, priorW = 15;
  const bayesian = (priorW * prior + count * avgRating) / (priorW + count);
  return clamp(((bayesian - 1) / 4) * 100);
}

function calcSafety(safetyAvg: number, negKeywords: number, total: number): number {
  if (total === 0) return 60;
  const base    = ((safetyAvg - 1) / 4) * 100;
  const negRatio = negKeywords / (total + 1);
  return clamp(base - clamp(negRatio * 200) * 0.3);
}

function calcTrendDelta(recent: number, previous: number): number {
  if (previous === 0) return 0;
  return Math.max(-5, Math.min(5, recent - previous));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body    = await req.json().catch(() => ({}));
    const province = body.province as string | undefined;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE);

    // 1. Hesaplanacak mahalleleri çek
    let query = supabase
      .from("neighborhood_scores")
      .select("province, district, neighborhood, area_sq_km, has_metro_access, walk_score");

    if (province) {
      query = query.eq("province", province);
    }

    const { data: neighborhoods, error: nErr } = await query;
    if (nErr) throw nErr;

    const results: Array<{
      neighborhood: string;
      score: number;
      updated: boolean;
    }> = [];

    for (const nb of neighborhoods ?? []) {
      // 2. Bu mahallenin feedback'lerini çek
      const { data: feedbacks } = await supabase
        .from("feedbacks")
        .select("category, rating, comment, ai_sentiment")
        .eq("province", nb.province)
        .eq("district", nb.district)
        .eq("neighborhood", nb.neighborhood)
        .eq("is_hidden", false);

      const fbs = feedbacks ?? [];
      const total = fbs.length;

      // 3. Kategori ortalamalarını hesapla
      const byCategory: Record<string, number[]> = {};
      for (const fb of fbs) {
        if (!byCategory[fb.category]) byCategory[fb.category] = [];
        byCategory[fb.category].push(fb.rating);
      }
      const avg = (arr: number[]) =>
        arr.length === 0 ? 3 : arr.reduce((a, b) => a + b, 0) / arr.length;

      const allRatings = fbs.map((f: any) => f.rating);
      const globalAvg  = avg(allRatings);

      // 4. Güvenlik anahtar kelime analizi
      const negSecurityKeywords = [
        "tehlike", "güvensiz", "soygun", "hırsız", "kavga", "karanlık", "korku"
      ];
      let negSecurityCount = 0;
      for (const fb of fbs) {
        const text = (fb.comment ?? "").toLowerCase();
        if (negSecurityKeywords.some((kw) => text.includes(kw))) {
          negSecurityCount++;
        }
      }

      // 5. Mekan verilerini çek
      const { data: places } = await supabase
        .from("places")
        .select("category, avg_rating, monthly_visits, is_tourist_spot")
        .eq("province", nb.province)
        .eq("district", nb.district)
        .eq("neighborhood", nb.neighborhood)
        .eq("is_active", true);

      const pls = places ?? [];
      const placeCount     = pls.length;
      const touristPlaces  = pls.filter((p: any) => p.is_tourist_spot).length;
      const cafeRestaurant = pls.filter((p: any) =>
        ["cafe", "restaurant"].includes(p.category)).length;
      const eventPlaces    = pls.filter((p: any) =>
        ["entertainment", "bar"].includes(p.category)).length;
      const openSpaces     = pls.filter((p: any) =>
        ["park", "nature"].includes(p.category)).length;
      const monthlyVisits  = pls.reduce((s: number, p: any) =>
        s + (p.monthly_visits ?? 0), 0);
      const avgPlaceLike   = pls.length > 0
        ? pls.reduce((s: number, p: any) => s + ((p.avg_rating ?? 3) / 5), 0) / pls.length
        : 0.5;

      // 6. Trend hesapla (son 30 gün vs önceki 30 gün)
      const now      = new Date();
      const day30ago = new Date(now.getTime() - 30 * 86400000).toISOString();
      const day60ago = new Date(now.getTime() - 60 * 86400000).toISOString();

      const recentFbs  = fbs.filter((f: any) => f.created_at >= day30ago);
      const prevFbs    = fbs.filter((f: any) =>
        f.created_at >= day60ago && f.created_at < day30ago);

      const recentAvg  = avg(recentFbs.map((f: any) => f.rating));
      const prevAvg    = avg(prevFbs.map((f: any) => f.rating));
      const trendDelta = calcTrendDelta(recentAvg * 20, prevAvg * 20);

      // 7. Her alt skoru hesapla
      const touristInterest = clamp(
        (touristPlaces / 20 * 100) * 0.40 +
        (avgPlaceLike * 100) * 0.35 +
        (Math.min(monthlyVisits / 5000, 1) * 100) * 0.25
      );

      const reviewActivityRate = total > 0
        ? recentFbs.length / total
        : 0.1;

      const socialLife = clamp(
        (cafeRestaurant / 30 * 100) * 0.35 +
        (eventPlaces / 10 * 100) * 0.25 +
        (openSpaces / 5 * 100) * 0.20 +
        (reviewActivityRate * 100) * 0.20
      );

      const userSatisfaction = calcUserSatisfaction(globalAvg, total);

      const transitStops = nb.has_metro_access ? 3 : 1;
      const accessibility = clamp(
        (transitStops / 5 * 100) * 0.40 +
        (nb.has_metro_access ? 20 : 0) * 0.30 +
        ((nb.walk_score ?? 50)) * 0.30
      );

      const cleanAvg   = avg(byCategory["cleaning"] ?? []);
      const cleanliness = clamp(((cleanAvg - 1) / 4) * 100);

      const safeAvg   = avg(byCategory["security"] ?? []);
      const safety    = calcSafety(safeAvg, negSecurityCount, total);

      const areaSqKm   = nb.area_sq_km ?? 1;
      const venueDensity = clamp(placeCount / areaSqKm / 20 * 100);

      // 8. Toplam skor
      const totalScore = clamp(
        touristInterest   * W.touristInterest  +
        socialLife        * W.socialLife        +
        userSatisfaction  * W.userSatisfaction  +
        accessibility     * W.accessibility     +
        cleanliness       * W.cleanliness       +
        safety            * W.safety            +
        venueDensity      * W.venueDensity      +
        trendDelta
      );

      const trendDir = trendDelta > 1.5
        ? "rising" : trendDelta < -1.5 ? "falling" : "stable";

      // 9. Veritabanını güncelle
      const { error: updateErr } = await supabase
        .from("neighborhood_scores")
        .update({
          overall_score:     totalScore,
          total_feedbacks:   total,
          tourist_interest:  touristInterest,
          social_life:       socialLife,
          user_satisfaction: userSatisfaction,
          accessibility:     accessibility,
          cleanliness:       cleanliness,
          safety:            safety,
          venue_density:     venueDensity,
          trend_delta:       trendDelta,
          trend_direction:   trendDir,
          place_count:       placeCount,
          last_updated:      new Date().toISOString(),
        })
        .eq("province", nb.province)
        .eq("district", nb.district)
        .eq("neighborhood", nb.neighborhood);

      if (updateErr) {
        console.error(`Error updating ${nb.neighborhood}:`, updateErr.message);
      }

      results.push({
        neighborhood: nb.neighborhood,
        score: Math.round(totalScore * 10) / 10,
        updated: !updateErr,
      });
    }

    // 10. Günlük skor snapshot kaydet
    const { error: snapshotErr } = await supabase.rpc("record_daily_score_snapshot");
    if (snapshotErr) {
      console.warn("Snapshot warning:", snapshotErr.message);
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: results.length,
        results: results.slice(0, 20),  // ilk 20 sonucu döndür
        timestamp: new Date().toISOString(),
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err: any) {
    console.error("recalculate-scores error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

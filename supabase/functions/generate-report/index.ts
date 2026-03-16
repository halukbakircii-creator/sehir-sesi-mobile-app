// supabase/functions/generate-report/index.ts
// Mahalle veya belediye için AI raporu oluşturur

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { type, province, district, neighborhood } = await req.json();
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    let report = "";

    if (type === "neighborhood") {
      // Mahalle skoru ve son 50 geri bildirim
      const [{ data: score }, { data: recentFeedbacks }] = await Promise.all([
        supabase
          .from("neighborhood_scores")
          .select("*")
          .eq("province", province)
          .eq("district", district)
          .eq("neighborhood", neighborhood)
          .single(),
        supabase
          .from("feedbacks")
          .select("category, rating, comment, ai_sentiment, ai_urgency")
          .eq("province", province)
          .eq("district", district)
          .eq("neighborhood", neighborhood)
          .order("created_at", { ascending: false })
          .limit(50),
      ]);

      const issues = recentFeedbacks
        ?.filter((f) => f.ai_sentiment === "negative" || f.rating <= 2)
        .slice(0, 5)
        .map((f) => f.comment.substring(0, 80))
        .join("\n") ?? "";

      const praises = recentFeedbacks
        ?.filter((f) => f.ai_sentiment === "positive" || f.rating >= 4)
        .slice(0, 5)
        .map((f) => f.comment.substring(0, 80))
        .join("\n") ?? "";

      const aiResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 1000,
          system: "Sen belediye danışmanısın. Türkçe, profesyonel raporlar yazıyorsun.",
          messages: [{
            role: "user",
            content: `
Mahalle Analiz Raporu: ${neighborhood}, ${district}, ${province}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Genel Memnuniyet: %${score?.overall_score ?? 0}
Toplam Geri Bildirim: ${score?.total_feedbacks ?? 0}

Kategori Puanları:
• Temizlik: %${score?.score_cleaning ?? 0}
• Yol/Altyapı: %${score?.score_road ?? 0}
• Güvenlik: %${score?.score_security ?? 0}
• Park/Yeşil Alan: %${score?.score_park ?? 0}
• Ulaşım: %${score?.score_transport ?? 0}
• Sosyal Hizmetler: %${score?.score_social ?? 0}

Öne Çıkan Şikayetler:
${issues || "Şikayet yok"}

Öne Çıkan Memnuniyetler:
${praises || "Yorum yok"}

3 bölümlü analiz yaz:
1. **Genel Değerlendirme** (2-3 cümle)
2. **Kritik Sorunlar ve Eylem Önerileri** (madde madde)
3. **Güçlü Yönler ve Sürdürülmesi Gerekenler** (madde madde)
`,
          }],
        }),
      });

      const aiData = await aiResponse.json();
      report = aiData.content[0].text;

      // Skora kaydet
      await supabase
        .from("neighborhood_scores")
        .update({ ai_report: report, ai_report_at: new Date().toISOString() })
        .eq("province", province)
        .eq("district", district)
        .eq("neighborhood", neighborhood);

    } else if (type === "municipality") {
      // İlçe bazlı özet
      const { data: districts } = await supabase
        .from("neighborhood_scores")
        .select("district, overall_score, total_feedbacks")
        .eq("province", province)
        .order("overall_score", { ascending: true });

      const districtSummary = districts?.reduce((acc: Record<string, { total: number; count: number; feedbacks: number }>, row) => {
        if (!acc[row.district]) acc[row.district] = { total: 0, count: 0, feedbacks: 0 };
        acc[row.district].total += row.overall_score;
        acc[row.district].count += 1;
        acc[row.district].feedbacks += row.total_feedbacks;
        return acc;
      }, {}) ?? {};

      const districtLines = Object.entries(districtSummary)
        .map(([d, v]) => `${d}: %${(v.total / v.count).toFixed(1)} (${v.feedbacks} geri bildirim)`)
        .join("\n");

      const criticalNeighborhoods = districts
        ?.filter((d) => d.overall_score < 40)
        .map((d) => `${d.neighborhood} - %${d.overall_score}`)
        .join(", ");

      const aiResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 1500,
          system: "Sen şehir planlama uzmanısın. Belediye başkanlarına yönelik stratejik raporlar hazırlıyorsun.",
          messages: [{
            role: "user",
            content: `
${province} Büyükşehir Belediyesi — Yönetici Özeti
═══════════════════════════════════════════════════

İlçe Bazlı Memnuniyet Puanları:
${districtLines}

Kritik Mahalleler (<%40):
${criticalNeighborhoods || "Yok"}

Şu bölümleri içeren kapsamlı rapor yaz:
1. **Yönetici Özeti** (3-4 cümle, sayılarla)
2. **Öncelikli Eylem Planı** (en kritik 5 madde)
3. **Kaynak Tahsisi Önerileri**
4. **6 Aylık Hedefler**
5. **Başarı Kriterleri**
`,
          }],
        }),
      });

      const aiData = await aiResponse.json();
      report = aiData.content[0].text;
    }

    return new Response(JSON.stringify({ success: true, report }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

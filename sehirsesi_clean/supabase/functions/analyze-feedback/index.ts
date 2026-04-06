// supabase/functions/analyze-feedback/index.ts
// Supabase Edge Function: Geri bildirimi AI ile analiz et

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
    const { feedback_id } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Geri bildirimi al
    const { data: feedback, error } = await supabase
      .from("feedbacks")
      .select("*")
      .eq("id", feedback_id)
      .single();

    if (error || !feedback) {
      throw new Error("Feedback bulunamadı");
    }

    // Claude API'ye gönder
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 300,
        system: `Sen Türk belediyesi için geri bildirim analisti.
JSON formatında yanıt ver, başka hiçbir şey yazma:
{"sentiment":"positive|negative|neutral","summary":"max 150 karakter özet","urgency":"low|medium|high","tags":["etiket1","etiket2"]}`,
        messages: [{
          role: "user",
          content: `Mahalle: ${feedback.neighborhood}, ${feedback.district}
Kategori: ${feedback.category}
Puan: ${feedback.rating}/5
Yorum: ${feedback.comment}`,
        }],
      }),
    });

    const aiData = await response.json();
    const text = aiData.content[0].text;
    const cleaned = text.replace(/```json|```/g, "").trim();
    const analysis = JSON.parse(cleaned);

    // Sonucu güncelle
    await supabase
      .from("feedbacks")
      .update({
        ai_sentiment: analysis.sentiment,
        ai_summary: analysis.summary,
        ai_urgency: analysis.urgency,
        ai_processed: true,
      })
      .eq("id", feedback_id);

    // Kritik ise belediyeye bildirim gönder
    if (analysis.urgency === "high") {
      await supabase.from("notifications").insert({
        title: "⚠️ Kritik Şikayet",
        body: `${feedback.neighborhood} mahallesinde acil durum: ${analysis.summary}`,
        data: { feedback_id, neighborhood: feedback.neighborhood, category: feedback.category },
      });
    }

    return new Response(JSON.stringify({ success: true, analysis }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

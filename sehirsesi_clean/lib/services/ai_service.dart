// lib/services/ai_service.dart
// Claude AI entegrasyonu - .env'den güvenli key okuma

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

class AIService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  static String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  late final Dio _dio;

  AIService() {
    _dio = Dio(BaseOptions(
      headers: {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<Map<String, String>> analyzeFeedback({
    required String comment,
    required String category,
    required int rating,
    required String neighborhood,
  }) async {
    try {
      final response = await _dio.post(_apiUrl, data: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 500,
        'system': 'Sen bir Türk belediyesi için çalışan AI asistanısın.\nVatandaşların geri bildirimlerini analiz ediyorsun.\nYanıtlarını SADECE JSON formatında ver.\nFormat: {"sentiment": "positive|negative|neutral", "summary": "kısa özet", "urgency": "low|medium|high"}',
        'messages': [{'role': 'user', 'content': 'Mahalle: $neighborhood\nKategori: $category\nPuan: $rating/5\nYorum: $comment\n\nBu geri bildirimi analiz et.'}],
      }));

      final content = response.data['content'][0]['text'] as String;
      final cleaned = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      return {
        'sentiment': parsed['sentiment'] ?? 'neutral',
        'summary': parsed['summary'] ?? comment.substring(0, comment.length.clamp(0, 100)),
        'urgency': parsed['urgency'] ?? 'low',
      };
    } catch (e) {
      return {
        'sentiment': rating >= 4 ? 'positive' : rating <= 2 ? 'negative' : 'neutral',
        'summary': comment.length > 100 ? '${comment.substring(0, 100)}...' : comment,
        'urgency': rating <= 2 ? 'high' : 'low',
      };
    }
  }

  Future<String> generateNeighborhoodReport(NeighborhoodStats stats) async {
    try {
      final categoryData = stats.categoryScores.entries
          .map((e) => '${e.key.label}: ${e.value.toStringAsFixed(0)}/100')
          .join('\n');

      final response = await _dio.post(_apiUrl, data: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 800,
        'system': 'Sen bir belediye danışmanısın. Türkçe, profesyonel ve yapıcı raporlar yazıyorsun.',
        'messages': [{'role': 'user', 'content': 'Mahalle: ${stats.neighborhood}, ${stats.district}, ${stats.province}\nGenel: %${stats.overallScore.toStringAsFixed(0)}\nKategori Puanları:\n$categoryData\n3 paragraflık analiz yaz: Genel Durum, Kritik Sorunlar ve Öneriler, Olumlu Yönler.'}],
      }));

      return response.data['content'][0]['text'] as String;
    } catch (e) {
      return 'Rapor oluşturulamadı. Lütfen daha sonra tekrar deneyin.';
    }
  }

  Future<String> generateMunicipalityReport({
    required String province,
    required double overallScore,
    required List<Map<String, dynamic>> districtData,
    required List<String> criticalIssues,
  }) async {
    try {
      final districtsText = districtData.map((d) => '${d['name']}: %${d['score']}').join('\n');

      final response = await _dio.post(_apiUrl, data: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 1200,
        'system': 'Sen bir şehir planlama uzmanısın. Belediye başkanlarına yönelik stratejik raporlar hazırlıyorsun.',
        'messages': [{'role': 'user', 'content': '$province Belediyesi Raporu\nGenel: %${overallScore.toStringAsFixed(1)}\nİlçeler:\n$districtsText\nKritik: ${criticalIssues.join(", ")}\n\nÖncelikli eylem planı ve 6 aylık hedefler içeren yönetici özeti hazırla.'}],
      }));

      return response.data['content'][0]['text'] as String;
    } catch (e) {
      return 'Belediye raporu oluşturulamadı.';
    }
  }

  Future<String> chatWithCitizen({
    required String question,
    required String neighborhood,
    required List<Map<String, String>> history,
  }) async {
    try {
      final messages = [
        ...history.map((h) => {'role': h['role'], 'content': h['content']}),
        {'role': 'user', 'content': question},
      ];

      final response = await _dio.post(_apiUrl, data: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 500,
        'system': 'Sen $neighborhood mahallesi için belediye asistanısın. Türkçe, samimi ve yardımsever yanıtlar ver.',
        'messages': messages,
      }));

      return response.data['content'][0]['text'] as String;
    } catch (e) {
      return 'Üzgünüm, şu an yanıt veremiyorum. Lütfen tekrar deneyin.';
    }
  }
}

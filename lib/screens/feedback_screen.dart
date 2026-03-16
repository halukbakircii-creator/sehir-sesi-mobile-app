// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart' as app_models;
import '../services/auth_service.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class FeedbackScreen extends StatefulWidget {
  final String? preselectedNeighborhood;
  const FeedbackScreen({super.key, this.preselectedNeighborhood});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  FeedbackCategory? _selectedCategory;
  int _rating = 3;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  Map<String, String>? _aiResult;

  final _aiService = AIService();
  final _supabaseService = SupabaseService();

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin')),
      );
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yorumunuzu yazın')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthService>();
    final profile = auth.profile;

    // Giriş yapmamışsa uyar
    if (!auth.isLoggedIn) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri bildirim vermek için giriş yapmalısınız')),
      );
      return;
    }

    final neighborhood = widget.preselectedNeighborhood ??
        profile?['neighborhood'] ?? '';
    final district = profile?['district'] ?? '';
    final province = profile?['province'] ?? '';

    try {
      // 1. Supabase'e kaydet
      if (!mounted) return;
      await _supabaseService.submitFeedback(
        province: province,
        district: district,
        neighborhood: neighborhood,
        category: _selectedCategory!,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );

      // 2. AI analizi (arka planda, hata olursa fallback)
      final aiResult = await _aiService.analyzeFeedback(
        comment: _commentCtrl.text,
        category: _selectedCategory!.label,
        rating: _rating,
        neighborhood: neighborhood,
      );

      if (!mounted) return;
      setState(() {
        _aiResult = aiResult;
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gönderilemedi: $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Geri Bildirim Ver'),
        backgroundColor: AppColors.primary,
      ),
      body: _submitted ? _buildSuccessView() : _buildForm(),
    );
  }

  Widget _buildForm() {
    final user = context.watch<AuthService>().currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konum bilgisi
          _buildLocationCard(user),
          const SizedBox(height: 20),

          // Kategori seçimi
          _buildSectionTitle('Kategori Seçin'),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
          const SizedBox(height: 20),

          // Puanlama
          _buildSectionTitle('Memnuniyet Puanı'),
          const SizedBox(height: 12),
          _buildRatingSelector(),
          const SizedBox(height: 20),

          // Yorum
          _buildSectionTitle('Yorumunuz'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Mahalleniz hakkında düşüncelerinizi paylaşın...',
            ),
          ),
          const SizedBox(height: 24),

          // Gönder butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('AI analiz ediyor...'),
                      ],
                    )
                  : const Text(
                      '📤 Gönder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

 Widget _buildLocationCard(dynamic user) {
  return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.preselectedNeighborhood != null
                  ? '${widget.preselectedNeighborhood}, ${user?.district ?? ""}, ${user?.province ?? ""}'
                  : '${user?.neighborhood ?? ""}, ${user?.district ?? ""}, ${user?.province ?? ""}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: FeedbackCategory.values.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? cat.color.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? cat.color : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: cat.color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat.icon,
                  color: isSelected ? cat.color : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cat.color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSelector() {
    final labels = ['Çok Kötü', 'Kötü', 'Orta', 'İyi', 'Çok İyi'];
    final emojis = ['😡', '😞', '😐', '😊', '🤩'];
    final colors = [
      AppColors.unsatisfied,
      const Color(0xFFFF7043),
      AppColors.neutral,
      const Color(0xFF66BB6A),
      AppColors.satisfied,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            emojis[_rating - 1],
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            labels[_rating - 1],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors[_rating - 1],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final isSelected = _rating == i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? colors[i] : colors[i].withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors[i],
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : colors[i],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final sentiment = _aiResult?['sentiment'] ?? 'neutral';
    final summary = _aiResult?['summary'] ?? '';
    final urgency = _aiResult?['urgency'] ?? 'low';

    Color sentimentColor = AppColors.neutral;
    String sentimentEmoji = '😐';
    String sentimentLabel = 'Nötr';

    if (sentiment == 'positive') {
      sentimentColor = AppColors.satisfied;
      sentimentEmoji = '😊';
      sentimentLabel = 'Olumlu';
    } else if (sentiment == 'negative') {
      sentimentColor = AppColors.unsatisfied;
      sentimentEmoji = '😞';
      sentimentLabel = 'Olumsuz';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Başarı animasyonu
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.satisfied.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.satisfied, width: 3),
            ),
            child: const Center(
              child: Text('✅', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Geri Bildiriminiz Alındı!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belediyeye iletildi ve mahalle memnuniyet puanınıza eklendi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // AI Analiz kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'AI Analizi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _aiResultRow('Duygu Analizi', '$sentimentEmoji $sentimentLabel', sentimentColor),
                const Divider(color: Colors.white24, height: 20),
                _aiResultRow(
                  'Aciliyet',
                  urgency == 'high' ? '🔴 Yüksek' : urgency == 'medium' ? '🟡 Orta' : '🟢 Düşük',
                  urgency == 'high' ? AppColors.unsatisfied : urgency == 'medium' ? AppColors.neutral : AppColors.satisfied,
                ),
                const Divider(color: Colors.white24, height: 20),
                const Text(
                  'AI Özeti:',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Haritaya Dön'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Text(value, style: TextStyle(
          color: color, fontWeight: FontWeight.w700, fontSize: 13,
        )),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String province;
  final String district;
  final String neighborhood;
  const FeedbackScreen({super.key, required this.province, required this.district, required this.neighborhood});
  @override State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  FeedbackCategory? _selectedCat;
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isAnonymous = true;
  bool _loading = false;
  final bool _sent = false;

  static const _tickerMessages = [
    '✍️ Sesinizi duyurun — her yorum değiştirir',
    '📊 Geri bildirimler belediyeye iletilir',
    '🤖 AI analizle önceliklendirilir',
  ];

  static const _catData = [
    {'cat': FeedbackCategory.road,      'icon': '🛣️', 'label': 'Yollar',     'color': AppColors.catRoad},
    {'cat': FeedbackCategory.security,  'icon': '🔒', 'label': 'Güvenlik',   'color': AppColors.catSecurity},
    {'cat': FeedbackCategory.cleaning,  'icon': '🧹', 'label': 'Temizlik',   'color': AppColors.catCleaning},
    {'cat': FeedbackCategory.transport, 'icon': '🚌', 'label': 'Ulaşım',     'color': AppColors.catTransport},
    {'cat': FeedbackCategory.park,      'icon': '🌳', 'label': 'Yeşil Alan', 'color': AppColors.catPark},
    {'cat': FeedbackCategory.social,    'icon': '🤝', 'label': 'Sosyal',     'color': AppColors.catSocial},
  ];

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_selectedCat == null) { _showSnack('Kategori seçin'); return; }
    if (_rating == 0) { _showSnack('Puanlama yapın'); return; }
    setState(() => _loading = true);
    try {
      await SupabaseService().submitFeedback(
        province: widget.province,
        district: widget.district,
        neighborhood: widget.neighborhood,
        category: _selectedCat!,
        rating: _rating,
        comment: _commentCtrl.text,
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorumunuz gönderildi'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.purple,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      setState(() => _loading = false);
      _showSnack('Gönderim başarısız, tekrar deneyin');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.purple, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgContent,
      body: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const AppTicker(messages: _tickerMessages),
        _buildTopBar(),
        Expanded(child: _sent ? _buildSuccessView() : _buildForm()),
      ]),
      bottomNavigationBar: _sent ? null : Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
        color: AppColors.bg,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : WhiteFab(label: 'Gönder', icon: '🚀', onPressed: _submit),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        gradient: RadialGradient(center: const Alignment(.6, -1), radius: 1.5,
          colors: [AppColors.teal.withOpacity(.1), AppColors.bg]),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const AppBackButton(),
          Text('Geri Bildirim', style: AppText.serif(18)),
          const SizedBox(width: 36),
        ]),
        const SizedBox(height: 14),
        // Mahalle chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.03),
            border: Border.all(color: Colors.white.withOpacity(.06)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(gradient: AppGradients.cardPurple, border: Border.all(color: AppColors.purple.withOpacity(.2)), borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('📍', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.neighborhood, style: AppText.sans(14, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${widget.district} · ${widget.province}', style: AppText.sans(10, color: AppColors.text3)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('Kategori Seçin'),
        Wrap(spacing: 8, runSpacing: 8, children: _catData.map((d) {
          final cat = d['cat'] as FeedbackCategory;
          final selected = _selectedCat == cat;
          final color = d['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(.15) : Colors.white.withOpacity(.04),
                border: Border.all(color: selected ? color.withOpacity(.4) : Colors.white.withOpacity(.08)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(d['icon'] as String, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(d['label'] as String, style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.text3)),
              ]),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),
        const SectionLabel('Puanlama'),
        Row(children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Container(
            width: 44, height: 44, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: i < _rating ? AppColors.amber.withOpacity(.15) : Colors.white.withOpacity(.04),
              border: Border.all(color: i < _rating ? AppColors.amber.withOpacity(.35) : Colors.white.withOpacity(.08)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(i < _rating ? '⭐' : '☆',
              style: TextStyle(fontSize: 20, color: i < _rating ? null : AppColors.text3))),
          ),
        ))),
        const SizedBox(height: 20),
        const SectionLabel('Yorumunuz'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.purple.withOpacity(.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AÇIKLAMA (İSTEĞE BAĞLI)', style: AppText.label()),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4, maxLength: 500,
              style: AppText.sans(13, color: AppColors.text1),
              decoration: InputDecoration(
                hintText: 'Görüşlerinizi paylaşın...',
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.zero,
                counterStyle: AppText.label(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        // Anonim toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.03),
            border: Border.all(color: Colors.white.withOpacity(.06)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Anonim gönder', style: AppText.sans(13, color: AppColors.text2)),
            GestureDetector(
              onTap: () => setState(() => _isAnonymous = !_isAnonymous),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46, height: 26,
                decoration: BoxDecoration(
                  color: _isAnonymous ? AppColors.purple.withOpacity(.3) : Colors.white.withOpacity(.08),
                  border: Border.all(color: _isAnonymous ? AppColors.purple.withOpacity(.5) : Colors.white.withOpacity(.1)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _isAnonymous ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _isAnonymous ? AppColors.purpleLight : AppColors.text3,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('✅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Geri Bildiriminiz Alındı!', style: AppText.serif(26), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Sesiniz duyuldu. Belediye ekibi en kısa sürede değerlendirecektir.',
            style: AppText.sans(14, color: AppColors.text3).copyWith(height: 1.65),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          GradientButton(label: 'Geri Dön', icon: '←', onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

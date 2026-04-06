import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'feedback_screen.dart';

class NeighborhoodDetailScreen extends StatefulWidget {
  final NeighborhoodStats stats;
  const NeighborhoodDetailScreen({super.key, required this.stats});
  @override
  State<NeighborhoodDetailScreen> createState() => _NeighborhoodDetailScreenState();
}

class _NeighborhoodDetailScreenState extends State<NeighborhoodDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supabase = SupabaseService();
  late NeighborhoodStats _stats;
  List<Map<String, dynamic>> _feedbacks = [];
  bool _loadingFeedbacks = false;

  static const _tickerMessages = [
    '📍 Mahalle detay görünümü',
    '🤖 AI analiz raporu mevcut',
    '📊 Tüm kategoriler canlı güncelleniyor',
  ];

  @override
  void initState() {
    super.initState();
    _stats = widget.stats;
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshStats(),
      _loadFeedbacks(),
    ]);
  }

  Future<void> _refreshStats() async {
    try {
      final updated = await _supabase.getNeighborhoodScore(
        province: _stats.province,
        district: _stats.district,
        neighborhood: _stats.neighborhood,
      );
      if (!mounted || updated == null) return;
      setState(() => _stats = updated);
    } catch (_) {}
  }

  Future<void> _loadFeedbacks() async {
    if (mounted) setState(() => _loadingFeedbacks = true);
    try {
      final data = await _supabase.getNeighborhoodFeedbacks(
        province: _stats.province,
        district: _stats.district,
        neighborhood: _stats.neighborhood,
      );
      if (!mounted) return;
      setState(() {
        _feedbacks = data;
        _loadingFeedbacks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingFeedbacks = false);
    }
  }

  Future<void> _openFeedbackScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          province: _stats.province,
          district: _stats.district,
          neighborhood: _stats.neighborhood,
        ),
      ),
    );

    if (result == true) {
      await _refreshAll();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  NeighborhoodStats get s => _stats;
  SatisfactionLevel get _level => getSatisfactionLevel(s.overallScore);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgContent,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildGenel(),
              _buildYorumlar(),
              _buildAiRapor(),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        color: AppColors.bg,
        child: WhiteFab(
          label: 'Geri Bildirim Ver',
          icon: '✍️',
          onPressed: _openFeedbackScreen,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bg,
      child: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const AppTicker(messages: _tickerMessages),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          decoration: BoxDecoration(
            color: AppColors.bg,
            gradient: RadialGradient(
              center: const Alignment(.5, -1),
              radius: 1.5,
              colors: [_level.color.withOpacity(.08), AppColors.bg],
            ),
          ),
          child: Column(children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBackButton(),
                LiveBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildScoreRing(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.neighborhood, style: AppText.serif(26)),
                    const SizedBox(height: 4),
                    Text(
                      '${s.district} · ${s.province}'.toUpperCase(),
                      style: AppText.label(
                        color: AppColors.text3.withOpacity(.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _tag('↑ canlı güncel', AppColors.green),
                      _tag('💬 ${s.totalFeedbacks} yorum', AppColors.purpleLight),
                    ]),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 6,
              childAspectRatio: 2.2,
              children: [
                CategoryPill(
                  icon: '🛣️',
                  label: 'Yollar',
                  value: s.categoryScores[FeedbackCategory.road] ?? 0,
                  color: AppColors.catRoad,
                ),
                CategoryPill(
                  icon: '🔒',
                  label: 'Güvenlik',
                  value: s.categoryScores[FeedbackCategory.security] ?? 0,
                  color: AppColors.catSecurity,
                ),
                CategoryPill(
                  icon: '🧹',
                  label: 'Temizlik',
                  value: s.categoryScores[FeedbackCategory.cleaning] ?? 0,
                  color: AppColors.catCleaning,
                ),
                CategoryPill(
                  icon: '🚌',
                  label: 'Ulaşım',
                  value: s.categoryScores[FeedbackCategory.transport] ?? 0,
                  color: AppColors.catTransport,
                ),
                CategoryPill(
                  icon: '🌳',
                  label: 'Yeşil',
                  value: s.categoryScores[FeedbackCategory.park] ?? 0,
                  color: AppColors.catPark,
                ),
                CategoryPill(
                  icon: '🤝',
                  label: 'Sosyal',
                  value: s.categoryScores[FeedbackCategory.social] ?? 0,
                  color: AppColors.catSocial,
                ),
              ],
            ),
            const SizedBox(height: 18),
          ]),
        ),
        AnimatedBuilder(
          animation: _tabCtrl.animation!,
          builder: (_, __) => Container(
            color: AppColors.bg,
            child: Row(children: [
              _tabBtn(0, 'Genel'),
              _tabBtn(1, 'Yorumlar'),
              _tabBtn(2, 'AI Rapor'),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildScoreRing() {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 90,
          height: 90,
          child: CircularProgressIndicator(
            value: s.overallScore / 100,
            strokeWidth: 7,
            backgroundColor: Colors.white.withOpacity(.07),
            valueColor: AlwaysStoppedAnimation(_level.color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            s.overallScore.toStringAsFixed(0),
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text('PUAN', style: AppText.label(color: AppColors.text3)),
        ]),
      ]),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          border: Border.all(color: color.withOpacity(.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  Widget _tabBtn(int idx, String label) {
    final active = (_tabCtrl.animation!.value.round()) == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabCtrl.animateTo(idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.purple : Colors.transparent,
                width: 1.5,
              ),
              top: BorderSide(color: Colors.white.withOpacity(.05), width: .5),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
              color: active ? const Color(0xFFE9D5FF) : AppColors.text3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenel() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        const SectionLabel('Genel Durum'),
        AppCard(
          isPurple: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryBtn,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('📊', style: TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Text(
                'Genel Değerlendirme',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purpleLight,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              '${s.neighborhood} mahallesi, ${_level.label.toLowerCase()} kategorisinde. '
              'Toplam ${s.totalFeedbacks} vatandaş geri bildirimi analiz edilmiştir.',
              style: AppText.sans(12, color: AppColors.text2).copyWith(height: 1.65),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        const SectionLabel('Kategori Detayları'),
        ...FeedbackCategory.values.map((cat) {
          final value = s.categoryScores[cat] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(cat.label, style: AppText.sans(13, weight: FontWeight.w700)),
                  ]),
                  Text(
                    value.toStringAsFixed(0),
                    style: GoogleFonts.playfairDisplay(fontSize: 22, color: cat.color),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(.06),
                    valueColor: AlwaysStoppedAnimation(cat.color),
                  ),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildYorumlar() {
    if (_loadingFeedbacks) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }

    if (_feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Henüz yorum yok.', style: AppText.sans(16, color: AppColors.text3)),
            const SizedBox(height: 8),
            Text('İlk yorumu sen yap!', style: AppText.sans(13, color: AppColors.text3)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _refreshAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final c = _feedbacks[index];
          final stars = (c['rating'] as num?)?.toInt() ?? 0;
          final catName = (c['category'] ?? 'cleaning').toString();
          final cat = FeedbackCategory.values.firstWhere(
            (e) => e.name == catName,
            orElse: () => FeedbackCategory.cleaning,
          );
          final comment = (c['comment'] ?? '').toString().trim();
          final createdAt = DateTime.tryParse((c['created_at'] ?? '').toString());

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.025),
              border: Border(
                left: BorderSide(color: cat.color.withOpacity(.55), width: 2),
                right: BorderSide(color: Colors.white.withOpacity(.06)),
                top: BorderSide(color: Colors.white.withOpacity(.06)),
                bottom: BorderSide(color: Colors.white.withOpacity(.06)),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cat.label,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: cat.color,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                Text(
                  '★' * stars + '☆' * (5 - stars),
                  style: const TextStyle(fontSize: 11, color: AppColors.amber, letterSpacing: 1),
                ),
              ]),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"$comment"',
                  style: AppText.sans(12, color: AppColors.text2).copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.65,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  '📍 ${s.neighborhood} · ${s.district}',
                  style: AppText.sans(9.5, color: AppColors.text3, weight: FontWeight.w600),
                ),
                Text(
                  createdAt != null ? _ago(createdAt) : '',
                  style: AppText.sans(9.5, color: AppColors.text3.withOpacity(.5)),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildAiRapor() {
    final report = s.aiReport?.trim();
    if (report == null || report.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Henüz AI raporu yok.', style: AppText.sans(16, color: AppColors.text3)),
            const SizedBox(height: 8),
            Text('Yorumlar arttıkça otomatik oluşur.', style: AppText.sans(13, color: AppColors.text3)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        AppCard(
          isPurple: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryBtn,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Değerlendirme',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purpleLight,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(report, style: AppText.sans(12, color: AppColors.text2).copyWith(height: 1.7)),
          ]),
        ),
      ],
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} saat önce';
    return '${d.inDays} gün önce';
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'neighborhood_detail_screen.dart';
import 'city_selection_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});
  @override State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supabase = SupabaseService();
  final _searchCtrl = TextEditingController();

  String _selectedProvince = 'Gaziantep';
  String _selectedDistrict = 'Şahinbey';
  List<NeighborhoodStats> _neighborhoods = [];
  bool _loading = true;

  static const _tickerMessages = [
    '🔔 Bu hafta 14.832 vatandaş ses verdi',
    '🏆 Bağlarbaşı bu ay zirveye çıktı',
    '📍 Gaziantep\'te 127 yeni geri bildirim',
    '⚡ Köroğlu\'nda yol çalışması başladı',
    '✨ Şehitkamil temizlik puanı yükseldi',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));
    _loadSavedLocation(); // BUG #11 FIX: SharedPreferences'tan oku
  }

  // BUG #11 FIX: Sayfa açılınca kaydedilmiş il/ilçeyi yükle
  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('selected_city');
    final savedDistrict = prefs.getString('selected_district');
    if (savedCity != null && savedCity.isNotEmpty) {
      setState(() {
        _selectedProvince = savedCity;
        _selectedDistrict = savedDistrict ?? 
            (TurkeyData.districts[savedCity]?.first ?? 'Merkez');
      });
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase.getDistrictNeighborhoodScores(
        province: _selectedProvince,
        district: _selectedDistrict,
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (data.isEmpty) {
        _useDemoData();
      } else {
        setState(() {
          _neighborhoods = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      _useDemoData();
    }
  }

  void _useDemoData() {
    final demos = (TurkeyData.neighborhoods[_selectedDistrict] ??
        ['Merkez', 'Yeni Mahalle', 'Cumhuriyet', 'Bahçelievler', 'Atatürk'])
        .map((n) => NeighborhoodStats.sample(n, _selectedDistrict)).toList();
    setState(() { _neighborhoods = demos; _loading = false; });
  }

  double get _avgScore => _neighborhoods.isEmpty ? 0
      : _neighborhoods.map((n) => n.overallScore).reduce((a, b) => a + b) / _neighborhoods.length;

  @override
  void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgContent,
      body: Column(children: [
        _buildFixedHeader(),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildListTab(),
          _buildMapTab(),
          _buildCommentsTab(),
        ])),
      ]),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
        color: AppColors.bg,
        child: WhiteFab(label: 'Sesini Yükselt', icon: '🔔',
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()))),
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      color: AppColors.bg,
      child: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const AppTicker(messages: _tickerMessages),
        _buildBrandRow(),
        _buildStatsBand(),
        _buildTabBar(),
      ]),
    );
  }

  Widget _buildBrandRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        gradient: RadialGradient(center: const Alignment(-.3, -1), radius: 1.5,
          colors: [AppColors.purple.withOpacity(.12), AppColors.bg]),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // BUG #13 FIX: Logo tıklanınca ana sayfaya git
        Expanded(child: GestureDetector(
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(text: TextSpan(children: [
              TextSpan(text: 'Şehir', style: GoogleFonts.playfairDisplay(
                fontSize: 30, color: AppColors.text1, fontWeight: FontWeight.w700)),
              TextSpan(text: 'Sesi', style: GoogleFonts.playfairDisplay(
                fontSize: 30, color: AppColors.purpleLight, fontStyle: FontStyle.italic)),
            ])),
            const SizedBox(height: 4),
            Text('TÜRKİYE\'NİN NABZI', style: AppText.label()),
          ]),
        )),
        GestureDetector(
          onTap: _showLocationPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(.1),
              border: Border.all(color: AppColors.purple.withOpacity(.25)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_selectedProvince, style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purpleLight)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.purpleLight.withOpacity(.5), size: 16),
              ]),
              const SizedBox(height: 2),
              Text(_selectedDistrict.toUpperCase(),
                style: AppText.label(color: AppColors.purple.withOpacity(.5))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatsBand() {
    final total = _neighborhoods.fold(0, (s, n) => s + n.totalFeedbacks);
    final totalStr = total > 999 ? '${(total / 1000).toStringAsFixed(0)}K' : '$total';
    return IntrinsicHeight(
      child: Row(children: [
        _statCell(_avgScore.toStringAsFixed(0), 'Bölge Puanı', AppColors.purpleLight),
        Container(width: .5, color: Colors.white.withOpacity(.06)),
        _statCell('${_neighborhoods.length}', 'Mahalle', AppColors.text1),
        Container(width: .5, color: Colors.white.withOpacity(.06)),
        _statCell(totalStr, 'Ses', AppColors.teal),
      ]),
    );
  }

  Widget _statCell(String val, String lbl, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.025),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(.05), width: .5),
          bottom: BorderSide(color: Colors.white.withOpacity(.05), width: .5),
        ),
      ),
      child: Column(children: [
        Text(val, style: GoogleFonts.playfairDisplay(
          fontSize: 24, color: color, letterSpacing: -1, height: 1)),
        const SizedBox(height: 5),
        Text(lbl.toUpperCase(), style: AppText.label()),
      ]),
    ));
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.bg,
      child: AnimatedBuilder(
        animation: _tabCtrl.animation!,
        builder: (_, __) => Row(children: [
          _tabBtn(0, 'Liste'), _tabBtn(1, 'Harita'), _tabBtn(2, 'Yorumlar'),
        ]),
      ),
    );
  }

  Widget _tabBtn(int idx, String label) {
    final active = (_tabCtrl.animation!.value.round()) == idx;
    return Expanded(child: GestureDetector(
      onTap: () => _tabCtrl.animateTo(idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(
          bottom: BorderSide(color: active ? AppColors.purple : Colors.transparent, width: 1.5),
          top: BorderSide(color: Colors.white.withOpacity(.05), width: .5),
        )),
        child: Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w800,
            letterSpacing: .8, color: active ? const Color(0xFFE9D5FF) : AppColors.text3)),
      ),
    ));
  }

  // ── LİSTE ──────────────────────────────────────────────────────
  Widget _buildListTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    final sorted = [..._neighborhoods]..sort((a, b) => b.overallScore.compareTo(a.overallScore));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      itemCount: sorted.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sıralama', style: AppText.serif(21)),
              const SizedBox(height: 3),
              Text('Puana göre · ${sorted.length} mahalle',
                style: AppText.sans(10.5, color: AppColors.text3)),
            ]),
            const LiveBadge(),
          ]),
        );
        }
        return _rankCard(sorted[i - 1], i - 1);
      },
    );
  }

  Widget _rankCard(NeighborhoodStats stats, int rank) {
    final scoreColor = getSatisfactionLevel(stats.overallScore).color;
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => NeighborhoodDetailScreen(stats: stats))),
      child: AppCard(
        isPurple: rank == 0,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: rank == 0 ? AppColors.purple.withOpacity(.15) : Colors.white.withOpacity(.06),
                  border: Border.all(color: rank == 0 ? AppColors.purple.withOpacity(.25) : Colors.white.withOpacity(.08)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#${rank + 1}', style: GoogleFonts.manrope(fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: rank == 0 ? AppColors.purpleLight : AppColors.text3,
                  letterSpacing: .5)),
              ),
              if (rank == 0) const Padding(padding: EdgeInsets.only(left: 7),
                child: Text('🏆', style: TextStyle(fontSize: 14))),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(stats.overallScore.toStringAsFixed(0),
                style: GoogleFonts.playfairDisplay(
                  fontSize: rank == 0 ? 34 : 26, color: scoreColor,
                  letterSpacing: -2, height: 1)),
              Text(rank == 0 ? '↑ +4 bu hafta' : '→ değişmedi',
                style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700,
                  color: rank == 0 ? AppColors.green : AppColors.text3)),
            ]),
          ]),
          const SizedBox(height: 4),
          Text(stats.neighborhood, style: AppText.serif(rank == 0 ? 22 : 19)),
          const SizedBox(height: 3),
          Text('${stats.district} · ${stats.province}'.toUpperCase(),
            style: AppText.label(color: AppColors.text3.withOpacity(.8))),
          const SizedBox(height: 14),
          // BUG #12 FIX: 6 kategori de gösteriliyor
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 6, childAspectRatio: 2.6,
            children: [
              CategoryPill(icon: '🛣️', label: 'Yollar',
                value: stats.categoryScores[FeedbackCategory.road] ?? 0, color: AppColors.catRoad),
              CategoryPill(icon: '🔒', label: 'Güvenlik',
                value: stats.categoryScores[FeedbackCategory.security] ?? 0, color: AppColors.catSecurity),
              CategoryPill(icon: '🧹', label: 'Temizlik',
                value: stats.categoryScores[FeedbackCategory.cleaning] ?? 0, color: AppColors.catCleaning),
              CategoryPill(icon: '🚌', label: 'Ulaşım',
                value: stats.categoryScores[FeedbackCategory.transport] ?? 0, color: AppColors.catTransport),
              CategoryPill(icon: '🌳', label: 'Yeşil',
                value: stats.categoryScores[FeedbackCategory.park] ?? 0, color: AppColors.catPark),
              CategoryPill(icon: '🤝', label: 'Sosyal',
                value: stats.categoryScores[FeedbackCategory.social] ?? 0, color: AppColors.catSocial),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: .5, decoration: BoxDecoration(gradient: LinearGradient(
            colors: [Colors.transparent, Colors.white.withOpacity(.07), Colors.transparent]))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('💬 ${stats.totalFeedbacks} yorum',
              style: AppText.sans(10, color: AppColors.text3)),
            Text('Detay gör →', style: GoogleFonts.manrope(fontSize: 10.5,
              fontWeight: FontWeight.w800, color: AppColors.purpleLight, letterSpacing: .3)),
          ]),
        ]),
      ),
    );
  }

  // ── HARİTA ─────────────────────────────────────────────────────
  Widget _buildMapTab() {
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: TextField(
          controller: _searchCtrl, onChanged: (_) => setState(() {}),
          style: AppText.sans(14),
          decoration: const InputDecoration(
            hintText: 'Mahalle ara...',
            prefixIcon: Icon(Icons.search, color: AppColors.text3, size: 20),
            isDense: true),
        )),
      Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dot(AppColors.satisfied, 'Memnun ≥70%'),
          const SizedBox(width: 14),
          _dot(AppColors.neutral, 'Orta 40-70%'),
          const SizedBox(width: 14),
          _dot(AppColors.unsatisfied, 'Kötü <40%'),
        ])),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: .9,
          crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _gridCard(_filtered[i]),
      )),
    ]);
  }

  List<NeighborhoodStats> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    return q.isEmpty ? _neighborhoods
        : _neighborhoods.where((n) => n.neighborhood.toLowerCase().contains(q)).toList();
  }

  Widget _dot(Color c, String l) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(l, style: AppText.sans(9.5, color: AppColors.text3)),
  ]);

  Widget _gridCard(NeighborhoodStats stats) {
    final level = getSatisfactionLevel(stats.overallScore);
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => NeighborhoodDetailScreen(stats: stats))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.03),
          border: Border.all(color: Colors.white.withOpacity(.07)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Container(height: 4, decoration: BoxDecoration(
            color: level.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(padding: const EdgeInsets.all(11),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(level.emoji, style: const TextStyle(fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(7)),
                  child: Text('%${stats.overallScore.toStringAsFixed(0)}',
                    style: GoogleFonts.manrope(fontSize: 12,
                      fontWeight: FontWeight.w900, color: level.color))),
              ]),
              const SizedBox(height: 7),
              Text(stats.neighborhood,
                style: AppText.sans(13, weight: FontWeight.w700)
                    .copyWith(color: Colors.black87),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${stats.totalFeedbacks} bildirim',
                style: AppText.sans(9.5, color: AppColors.text3)),
              const SizedBox(height: 8),
              ...FeedbackCategory.values.take(3).map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ClipRRect(borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (stats.categoryScores[cat] ?? 0) / 100,
                    backgroundColor: Colors.white.withOpacity(.07),
                    valueColor: AlwaysStoppedAnimation(cat.color),
                    minHeight: 3)))),
            ])),
        ]),
      ),
    );
  }

  // ── YORUMLAR ───────────────────────────────────────────────────
  Widget _buildCommentsTab() => _CommentsTab(
    province: _selectedProvince, district: _selectedDistrict);

  // BUG #4 FIX: Location picker düzeltildi
  void _showLocationPicker() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CitySelectionScreen(
        isFirstTime: false,
        onSelected: (p, d) async {
          // SharedPreferences'a kaydet
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selected_city', p);
          await prefs.setString('selected_district', d);
          setState(() { _selectedProvince = p; _selectedDistrict = d; });
          _loadData();
        },
      ),
    ));
  }
}

// ─── Yorumlar Tab ─────────────────────────────────────────────────
class _CommentsTab extends StatefulWidget {
  final String province;
  final String district;
  const _CommentsTab({required this.province, required this.district});
  @override State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(_CommentsTab old) {
    super.didUpdateWidget(old);
    if (old.province != widget.province || old.district != widget.district) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('feedbacks')
          .select('neighborhood, category, rating, comment, created_at')
          .eq('province', widget.province)
          .eq('district', widget.district)
          .order('created_at', ascending: false)
          .limit(20);
      setState(() { _comments = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      setState(() { _comments = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    if (_comments.isEmpty) {
      return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💬', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Henüz yorum yok.', style: AppText.sans(16, color: AppColors.text3)),
        const SizedBox(height: 8),
        Text('İlk yorumu sen yap!', style: AppText.sans(13, color: AppColors.text3)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _comments.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Text('Son yorumlar — isimler gizlenmiştir',
            style: AppText.sans(12, color: AppColors.text3)));
        }
        final c = _comments[i - 1];
        final cat = FeedbackCategory.values.firstWhere(
          (e) => e.name == (c['category'] ?? 'cleaning'),
          orElse: () => FeedbackCategory.cleaning);
        final stars = (c['rating'] as num?)?.toInt() ?? 3;
        final createdAt = DateTime.tryParse(c['created_at'] ?? '');
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.025),
            border: Border(
              left: BorderSide(color: AppColors.purple.withOpacity(.4), width: 2),
              right: BorderSide(color: Colors.white.withOpacity(.06)),
              top: BorderSide(color: Colors.white.withOpacity(.06)),
              bottom: BorderSide(color: Colors.white.withOpacity(.06))),
            borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(.1), borderRadius: BorderRadius.circular(6)),
                child: Text(cat.label, style: GoogleFonts.manrope(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: cat.color, letterSpacing: .8))),
              Text('★' * stars + '☆' * (5 - stars),
                style: const TextStyle(fontSize: 11, color: AppColors.amber, letterSpacing: 1)),
            ]),
            const SizedBox(height: 8),
            if (c['comment'] != null)
              Text('"${c['comment']}"', style: AppText.sans(12, color: AppColors.text2)
                .copyWith(fontStyle: FontStyle.italic, height: 1.65)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('📍 ${c['neighborhood'] ?? ''} · ${widget.district}',
                style: AppText.sans(9.5, color: AppColors.text3, weight: FontWeight.w600)),
              Text(createdAt != null ? _ago(createdAt) : '',
                style: AppText.sans(9.5, color: AppColors.text3.withOpacity(.5))),
            ]),
          ]),
        );
      },
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} saat önce';
    return '${d.inDays} gün önce';
  }
}
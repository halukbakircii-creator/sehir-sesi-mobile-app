import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class MunicipalityDashboardScreen extends StatefulWidget {
  final String province;
  const MunicipalityDashboardScreen({super.key, required this.province});
  @override State<MunicipalityDashboardScreen> createState() => _MunicipalityDashboardScreenState();
}

class _MunicipalityDashboardScreenState extends State<MunicipalityDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supabase = SupabaseService();
  List<NeighborhoodStats> _neighborhoods = [];
  final List<Map<String, dynamic>> _recentFeedbacks = [];
  bool _loading = true;

  static const _tickerMessages = [
    '📊 Belediye Yönetim Paneli',
    '🔔 Kritik bildirimler önceliklendirildi',
    '🤖 AI raporu hazır — günlük özet',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)..addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Tüm ilçelerin verilerini çek
      final districts = TurkeyData.districts[widget.province] ?? [];
      final all = <NeighborhoodStats>[];
      for (final d in districts.take(3)) {
        final data = await _supabase.getDistrictNeighborhoodScores(province: widget.province, district: d);
        all.addAll(data);
      }
      setState(() { _neighborhoods = all; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  int get _totalFeedbacks => _neighborhoods.fold(0, (s, n) => s + n.totalFeedbacks);
  int get _criticalCount => _neighborhoods.where((n) => n.overallScore < 40).length;
  double get _avgScore => _neighborhoods.isEmpty ? 0 :
      _neighborhoods.map((n) => n.overallScore).reduce((a, b) => a + b) / _neighborhoods.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgContent,
      body: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const AppTicker(messages: _tickerMessages),
        _buildHeader(),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildGenel(),
          _buildBildirimler(),
          _buildRapor(),
        ])),
      ]),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
        color: AppColors.bg,
        child: WhiteFab(label: 'AI Raporu Oluştur', icon: '🤖', onPressed: () {}),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bg,
      child: Column(children: [
        // Hero
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            gradient: RadialGradient(center: const Alignment(-.4, -1), radius: 1.5,
              colors: [AppColors.teal.withOpacity(.1), AppColors.bg]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BELEDİYE PANELİ', style: AppText.label()),
                const SizedBox(height: 4),
                Text('${widget.province} Belediyesi', style: AppText.serif(22)),
              ]),
              Container(width: 44, height: 44,
                decoration: BoxDecoration(gradient: AppGradients.cardPurple, border: Border.all(color: AppColors.purple.withOpacity(.25)), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('🏛️', style: TextStyle(fontSize: 22)))),
            ]),
            const SizedBox(height: 16),
            // Stat grid
            Row(children: [
              Expanded(child: _miniStat(_avgScore.toStringAsFixed(0), 'Ort. Puan', AppColors.purpleLight)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('${_totalFeedbacks > 999 ? '${(_totalFeedbacks / 1000).toStringAsFixed(1)}K' : _totalFeedbacks}', 'Bu Ay Ses', AppColors.teal)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('$_criticalCount', 'Kritik', AppColors.red)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('${_neighborhoods.length}', 'Mahalle', AppColors.text2)),
            ]),
          ]),
        ),
        // Tab bar
        AnimatedBuilder(
          animation: _tabCtrl.animation!,
          builder: (_, __) => Container(
            color: AppColors.bg,
            child: Row(children: [
              _tabBtn(0, 'Genel'), _tabBtn(1, 'Bildirimler'), _tabBtn(2, 'Rapor'),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _miniStat(String val, String lbl, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.03),
      border: Border.all(color: Colors.white.withOpacity(.06)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: [
      Text(val, style: GoogleFonts.playfairDisplay(fontSize: 20, color: color, letterSpacing: -1, height: 1)),
      const SizedBox(height: 4),
      Text(lbl.toUpperCase(), style: AppText.label(), textAlign: TextAlign.center),
    ]),
  );

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
          style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .8,
            color: active ? const Color(0xFFE9D5FF) : AppColors.text3)),
      ),
    ));
  }

  // ── GENEL ───────────────────────────────────────────────────────
  Widget _buildGenel() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    final sorted = [..._neighborhoods]..sort((a, b) => b.overallScore.compareTo(a.overallScore));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SectionLabel('Mahalle Sıralaması'),
          LiveBadge(),
        ]),
        ...sorted.asMap().entries.map((e) => _rankRow(e.value, e.key)),
      ],
    );
  }

  Widget _rankRow(NeighborhoodStats stats, int rank) {
    final scoreColor = getSatisfactionLevel(stats.overallScore).color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.03),
        border: Border(
          left: BorderSide(color: scoreColor.withOpacity(.5), width: 2),
          right: BorderSide(color: Colors.white.withOpacity(.06)),
          top: BorderSide(color: Colors.white.withOpacity(.06)),
          bottom: BorderSide(color: Colors.white.withOpacity(.06)),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(width: 28, height: 28,
          decoration: BoxDecoration(color: rank < 3 ? scoreColor.withOpacity(.12) : Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('#${rank + 1}', style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w900,
            color: rank < 3 ? scoreColor : AppColors.text3)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(stats.neighborhood, style: AppText.sans(13, weight: FontWeight.w700)),
          Text(stats.district, style: AppText.sans(10, color: AppColors.text3)),
        ])),
        Text(stats.overallScore.toStringAsFixed(0),
          style: GoogleFonts.playfairDisplay(fontSize: 20, color: scoreColor, letterSpacing: -1)),
      ]),
    );
  }

  // ── BİLDİRİMLER ─────────────────────────────────────────────────
  Widget _buildBildirimler() {
    final mock = [
      {'n': 'Köroğlu', 'cat': '🛣️ Yol Hasarı', 'count': 47, 'level': 'Kritik', 'color': AppColors.red, 'day': 'Bugün'},
      {'n': 'Bostancı', 'cat': '🌳 Yeşil Alan', 'count': 23, 'level': 'Orta', 'color': AppColors.orange, 'day': 'Dün'},
      {'n': 'Gündoğdu', 'cat': '🚌 Ulaşım', 'count': 18, 'level': 'Düşük', 'color': AppColors.amber, 'day': '2 gün önce'},
      {'n': 'Suburcu', 'cat': '🧹 Temizlik', 'count': 12, 'level': 'Düşük', 'color': AppColors.amber, 'day': '3 gün önce'},
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        const SectionLabel('Bekleyen Bildirimler'),
        ...mock.map((m) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.03),
            border: Border(
              left: BorderSide(color: (m['color'] as Color).withOpacity(.6), width: 2),
              right: BorderSide(color: Colors.white.withOpacity(.06)),
              top: BorderSide(color: Colors.white.withOpacity(.06)),
              bottom: BorderSide(color: Colors.white.withOpacity(.06)),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${m['n']} — ${m['cat']}', style: AppText.sans(13, weight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(.12), borderRadius: BorderRadius.circular(6)),
                child: Text(m['level'] as String, style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w800, color: m['color'] as Color)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('${m['count']} şikayet · ${m['day']}', style: AppText.sans(10.5, color: AppColors.text3)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (m['count'] as int) / 50,
                backgroundColor: Colors.white.withOpacity(.07),
                valueColor: AlwaysStoppedAnimation(m['color'] as Color), minHeight: 4)),
          ]),
        )),
      ],
    );
  }

  // ── RAPOR ───────────────────────────────────────────────────────
  Widget _buildRapor() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        AppCard(isPurple: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(gradient: AppGradients.primaryBtn, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aylık AI Raporu', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purpleLight)),
              Text('Mart 2026 · Gemini Pro', style: AppText.label(color: AppColors.purple.withOpacity(.5))),
            ]),
          ]),
          const SizedBox(height: 14),
          Text('${widget.province} genelinde bu ay toplam $_totalFeedbacks vatandaş geri bildirimi analiz edilmiştir. '
            'Kritik bildirim sayısı $_criticalCount olup, genel memnuniyet ortalaması %${_avgScore.toStringAsFixed(0)} düzeyindedir. '
            'Öncelikli eylem gerektiren alan yol altyapısıdır.',
            style: AppText.sans(13, color: AppColors.text2).copyWith(height: 1.75)),
        ])),
        const SizedBox(height: 8),
        // Öncelikler
        const SectionLabel('Eylem Öncelikleri'),
        ...[
          {'icon': '🛣️', 'title': 'Yol Onarımı', 'desc': 'Köroğlu ve Bostancı mahalleleri öncelikli', 'color': AppColors.red},
          {'icon': '🌳', 'title': 'Yeşil Alan', 'desc': 'Park ve bahçe düzenlemesi gerekiyor', 'color': AppColors.orange},
          {'icon': '🚌', 'title': 'Ulaşım', 'desc': 'Sefer sıklığı artırılmalı', 'color': AppColors.amber},
        ].map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (item['color'] as Color).withOpacity(.05),
            border: Border.all(color: (item['color'] as Color).withOpacity(.15)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Text(item['icon'] as String, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['title'] as String, style: AppText.sans(13, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(item['desc'] as String, style: AppText.sans(11.5, color: AppColors.text3)),
            ])),
          ]),
        )),
      ],
    );
  }
}

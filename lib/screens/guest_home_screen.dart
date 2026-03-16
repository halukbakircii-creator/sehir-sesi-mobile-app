// lib/screens/guest_home_screen.dart
// Giriş yapmadan erişilebilen misafir görünümü

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'neighborhood_detail_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase.getDistrictNeighborhoodScores(
        province: _selectedProvince,
        district: _selectedDistrict,
      );
      setState(() {
        _neighborhoods = data;
        _updateAvgScore();
        _loading = false;
      });
    } catch (_) {
      // Demo data fallback
      setState(() {
        _neighborhoods = TurkeyData.neighborhoods[_selectedDistrict]
                ?.map((n) => NeighborhoodStats.sample(n, _selectedDistrict))
                .toList() ??
            [];
        _updateAvgScore();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double _avgScore = 0;

  void _updateAvgScore() {
    if (_neighborhoods.isEmpty) { _avgScore = 0; return; }
    _avgScore = _neighborhoods
        .map((n) => n.overallScore)
        .reduce((a, b) => a + b) / _neighborhoods.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCityScoreCard()),
          SliverToBoxAdapter(child: _buildTabBar()),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildMapTab(),
            _buildListTab(),
            _buildCommentsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildLoginFAB(),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      title: Column(
        children: [
          const Text('ŞehirSes', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
          )),
          Text('$_selectedProvince / $_selectedDistrict',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
        ],
      ),
      actions: [
        // Konum değiştir
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: _showLocationPicker,
        ),
        // Giriş yap
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: _goToLogin,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text('Giriş Yap',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildCityScoreCard() {
    final level = getSatisfactionLevel(_avgScore);
    final criticalCount = _neighborhoods.where((n) => n.overallScore < 40).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 20, offset: const Offset(0, 8),
        )],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_selectedDistrict Genel Skoru',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('%${_avgScore.toStringAsFixed(0)}', style: TextStyle(
                          fontSize: 42, fontWeight: FontWeight.w900,
                          color: level.color, height: 1,
                        )),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: level.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: level.color.withOpacity(0.5)),
                            ),
                            child: Text('${level.emoji} ${level.label}',
                              style: TextStyle(color: level.color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                    Text('${_neighborhoods.length} mahalle · '
                        '${_neighborhoods.fold(0, (s, n) => s + n.totalFeedbacks)} geri bildirim',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  _miniStat('$criticalCount', 'Kritik', AppColors.unsatisfied),
                  const SizedBox(height: 8),
                  _miniStat('${_neighborhoods.where((n) => n.overallScore >= 70).length}',
                      'İyi', AppColors.satisfied),
                ],
              ),
            ],
          ),

          // Kategori mini bar'lar
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: FeedbackCategory.values.map((cat) {
              final avg = _neighborhoods.isEmpty ? 0.0 :
                  _neighborhoods.map((n) => n.categoryScores[cat] ?? 0.0).reduce((a, b) => a + b) /
                  _neighborhoods.length;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${cat.icon} ${cat.label.split('/').first}',
                      style: const TextStyle(fontSize: 9, color: Colors.white60),
                      maxLines: 1),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: avg / 100,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(cat.color),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('%${avg.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 9, color: cat.color, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String val, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(val, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: '🗺️ Harita'),
          Tab(text: '📋 Liste'),
          Tab(text: '💬 Yorumlar'),
        ],
      ),
    );
  }

  // ─── TAB 1: Harita (Grid) ──────────────────────────────────
  Widget _buildMapTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Arama + Legend
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Mahalle ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(AppColors.satisfied, 'Memnun ≥70%'),
                  const SizedBox(width: 12),
                  _legendDot(AppColors.neutral, 'Orta 40-70%'),
                  const SizedBox(width: 12),
                  _legendDot(AppColors.unsatisfied, 'Kötü <40%'),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _filteredNeighborhoods.length,
            itemBuilder: (ctx, i) => _buildNeighborhoodCard(_filteredNeighborhoods[i]),
          ),
        ),
      ],
    );
  }

  List<NeighborhoodStats> get _filteredNeighborhoods {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _neighborhoods;
    return _neighborhoods.where((n) => n.neighborhood.toLowerCase().contains(q)).toList();
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildNeighborhoodCard(NeighborhoodStats stats) {
    final level = stats.satisfactionLevel;
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => NeighborhoodDetailScreen(stats: stats))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: level.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(level.emoji, style: const TextStyle(fontSize: 20)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: level.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('%${stats.overallScore.toStringAsFixed(0)}',
                          style: TextStyle(color: level.color, fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(stats.neighborhood, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${stats.totalFeedbacks} geri bildirim',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 7),
                  ...stats.categoryScores.entries.take(3).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(e.key.icon, size: 9, color: e.key.color),
                        const SizedBox(width: 3),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: e.value / 100,
                              backgroundColor: Colors.grey[100],
                              valueColor: AlwaysStoppedAnimation(e.key.color),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: Liste ──────────────────────────────────────────
  Widget _buildListTab() {
    final sorted = [..._neighborhoods]..sort((a, b) => b.overallScore.compareTo(a.overallScore));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final n = sorted[i];
        final level = n.satisfactionLevel;
        return GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => NeighborhoodDetailScreen(stats: n))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(
              children: [
                // Sıra
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: i < 3 ? [
                      const Color(0xFFFFD700),
                      const Color(0xFFC0C0C0),
                      const Color(0xFFCD7F32),
                    ][i].withOpacity(0.15) : Colors.grey[100]!,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('#${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 11,
                      color: i < 3 ? [
                        const Color(0xFFFFD700),
                        const Color(0xFF808080),
                        const Color(0xFFCD7F32),
                      ][i] : Colors.grey[500],
                    ))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.neighborhood, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('${n.totalFeedbacks} geri bildirim',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('%${n.overallScore.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: level.color)),
                    SizedBox(
                      width: 70, height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: n.overallScore / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(level.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 3: Yorumlar ───────────────────────────────────────
  Widget _buildCommentsTab() {
    // Demo yorumlar (gerçekte Supabase'den gelir)
    final comments = [
      {'neighborhood': 'Gazikent', 'cat': 'park', 'text': 'Parklar çok bakımlı, çocuklar rahatça oynuyor.', 'stars': 5, 'time': '2 saat önce'},
      {'neighborhood': 'Akkent', 'cat': 'road', 'text': '3. sokaktaki çukur hâlâ düzeltilmedi.', 'stars': 2, 'time': '4 saat önce'},
      {'neighborhood': 'Sultanbey', 'cat': 'cleaning', 'text': 'Çöpler düzenli toplanıyor, mahalle temiz.', 'stars': 4, 'time': '6 saat önce'},
      {'neighborhood': 'Onur', 'cat': 'security', 'text': 'Gece aydınlatma yok, tehlikeli.', 'stars': 1, 'time': '8 saat önce'},
      {'neighborhood': 'Mücahitler', 'cat': 'transport', 'text': 'Yeni otobüs hattı çok işe yaradı.', 'stars': 5, 'time': '10 saat önce'},
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        Text('Son yorumlar — isimler gizlenmiştir',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ...comments.map((c) {
          final cat = FeedbackCategory.values.firstWhere(
            (e) => e.name == c['cat'],
            orElse: () => FeedbackCategory.cleaning,
          );
          final stars = c['stars'] as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${cat.label}',
                            style: TextStyle(color: cat.color, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Text('${c['neighborhood']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    Text('⭐' * stars + '☆' * (5 - stars), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${c['text']}', style: const TextStyle(fontSize: 13, height: 1.5)),
                const SizedBox(height: 6),
                Text('🕐 ${c['time']}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          );
        }),

        // Giriş yap CTA
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _goToLogin,
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('Sen de yorum yap — Giriş Yap'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ─── Giriş yap FAB ────────────────────────────────────────
  Widget _buildLoginFAB() {
    return FloatingActionButton.extended(
      onPressed: _goToLogin,
      backgroundColor: AppColors.secondary,
      icon: const Icon(Icons.edit_note, color: Colors.white),
      label: const Text('Geri Bildirim Ver',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  void _goToLogin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoginPromptSheet(
        onLogin: () {
          Navigator.pop(context);
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
        },
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Şehir Seç', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              decoration: const InputDecoration(labelText: 'İl'),
              items: TurkeyData.provinces.map((p) =>
                DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() { _selectedProvince = v!; }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: const InputDecoration(labelText: 'İlçe'),
              items: (TurkeyData.districts[_selectedProvince] ?? []).map((d) =>
                DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() { _selectedDistrict = v!; }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _loadData(); },
                child: const Text('Ara'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Giriş prompt bottom sheet
class _LoginPromptSheet extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginPromptSheet({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text('🔐', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          const Text('Geri Bildirim Vermek İçin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('TC Kimlik ile güvenli giriş yapın',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.phone_android),
              label: const Text('TC Kimlik + SMS ile Giriş',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Vazgeç, sadece bakıyorum',
                style: TextStyle(color: Colors.grey[500])),
            ),
          ),
          const SizedBox(height: 8),
          Text('🛡️ KVKK uyumlu · TC Kimlik şifrelenir',
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

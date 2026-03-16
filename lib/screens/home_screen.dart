// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import 'feedback_screen.dart';
import 'neighborhood_detail_screen.dart';
import 'municipality_dashboard_screen.dart';
import 'city_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  String _selectedProvince = 'Gaziantep';
  String _selectedDistrict = 'Şahinbey';
  late TabController _tabCtrl;
  final _supabase = SupabaseService();
  bool _loading = false;

  List<NeighborhoodStats> _neighborhoodStats = [];
  double _avgScore = 0;
  int _totalFeedbacks = 0;

  void _updateStats() {
    if (_neighborhoodStats.isEmpty) {
      _avgScore = 0;
      _totalFeedbacks = 0;
      return;
    }
    _avgScore = _neighborhoodStats
        .map((n) => n.overallScore)
        .reduce((a, b) => a + b) / _neighborhoodStats.length;
    _totalFeedbacks = _neighborhoodStats
        .fold(0, (s, n) => s + n.totalFeedbacks);
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('selected_city');
    final district = prefs.getString('selected_district');
    if (!mounted) return;
    if (city != null) setState(() => _selectedProvince = city);
    if (district != null) setState(() => _selectedDistrict = district);
    await _loadNeighborhoodData();
  }

  Future<void> _loadNeighborhoodData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _supabase.getDistrictNeighborhoodScores(
        province: _selectedProvince,
        district: _selectedDistrict,
      );
      if (!mounted) return;
      setState(() {
        _neighborhoodStats = data;
        _updateStats();
        _loading = false;
      });
    } catch (_) {
      // Supabase bağlantısı yoksa boş liste — fake skor gösterme
      if (!mounted) return;
      setState(() {
        _neighborhoodStats = [];
        _updateStats();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Column(
        children: [
          const Text(
            'ŞehirSes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            '$_selectedProvince / $_selectedDistrict',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: _showLocationPicker,
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_selectedTab) {
      case 0:
        return _buildMapView();
      case 1:
        return _buildAssistantTab();
      case 2:
        return const MunicipalityDashboardScreen();
      case 3:
        return _buildProfileTab();
      default:
        return _buildMapView();
    }
  }

  Widget _buildAssistantTab() {
    final auth = context.read<AuthService>();
    final neighborhood = auth.profile?['neighborhood'] ?? _selectedDistrict;
    return _AIAssistantView(neighborhood: neighborhood, district: _selectedDistrict);
  }

  Widget _buildProfileTab() {
    final auth = context.read<AuthService>();
    final profile = auth.profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                  child: const Center(child: Text('👤', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?['neighborhood'] ?? 'Kullanıcı',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${profile?['district'] ?? ''}, ${profile?['province'] ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _profileRow(Icons.location_on_outlined, 'Konum',
              '${profile?['neighborhood'] ?? '-'}, ${profile?['district'] ?? '-'}'),
          _profileRow(Icons.phone_outlined, 'Telefon', profile?['phone'] ?? '-'),
          _profileRow(Icons.verified_outlined, 'Doğrulama',
              profile?['is_verified'] == true ? 'Doğrulandı ✅' : 'Bekliyor'),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CitySelectionScreen())),
            icon: const Icon(Icons.edit_location_outlined),
            label: const Text('Konumu Değiştir'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthService>().logout();
            },
            icon: const Icon(Icons.logout, color: AppColors.unsatisfied),
            label: const Text('Çıkış Yap', style: TextStyle(color: AppColors.unsatisfied)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.unsatisfied.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_neighborhoodStats.isEmpty) {
      return _buildEmptyState();
    }
    return CustomScrollView(
      slivers: [
        // Filtre + Özet
        SliverToBoxAdapter(child: _buildSummaryCard()),
        // Legend
        SliverToBoxAdapter(child: _buildLegend()),
        // Mahalle Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildNeighborhoodCard(_neighborhoodStats[i]),
              childCount: _neighborhoodStats.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏘️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text(
              'Henüz veri yok',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bu mahalle için henüz geri bildirim girilmemiş.\nİlk geri bildirimi sen ver!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
              ),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Geri Bildirim Ver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadNeighborhoodData,
              child: const Text(
                'Yenile',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final avg = _avgScore;
    final level = getSatisfactionLevel(avg);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(120)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedDistrict İlçesi',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '%${avg.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: level.color.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: level.color.withOpacity(0.6)),
                        ),
                        child: Text(
                          level.label,
                          style: TextStyle(
                            color: level.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Genel Memnuniyet ${level.emoji}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildMiniStat('${_neighborhoodStats.length}', 'Mahalle'),
              const SizedBox(height: 8),
              _buildMiniStat(
                '${_neighborhoodStats.fold(0, (s, n) => s + n.totalFeedbacks)}',
                'Geri Bildirim',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(AppColors.satisfied, 'Memnun ≥70%'),
          _legendItem(AppColors.neutral, 'Orta 40-70%'),
          _legendItem(AppColors.unsatisfied, 'Kötü <40%'),
          _legendItem(AppColors.noData, 'Veri Yok'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNeighborhoodCard(NeighborhoodStats stats) {
    final level = stats.satisfactionLevel;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NeighborhoodDetailScreen(stats: stats),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renk şeridi
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: level.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        level.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: level.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '%${stats.overallScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: level.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats.neighborhood,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.totalFeedbacks} geri bildirim',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mini kategori çubukları
                  _buildMiniCategoryBars(stats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCategoryBars(NeighborhoodStats stats) {
    final top3 = stats.categoryScores.entries.take(3).toList();
    return Column(
      children: top3.map((e) {
        final pct = (e.value / 100).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              Icon(e.key.icon, size: 9, color: e.key.color),
              const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation(e.key.color),
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.map_outlined, Icons.map, 'Harita'),
              _navItem(1, Icons.chat_bubble_outline, Icons.chat_bubble, 'Asistan'),
              const SizedBox(width: 40),
              _navItem(2, Icons.bar_chart_outlined, Icons.bar_chart, 'Raporlar'),
              _navItem(3, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FeedbackScreen()),
      ),
      backgroundColor: AppColors.secondary,
      child: const Icon(Icons.add_comment, color: Colors.white),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LocationPickerSheet(
        selectedProvince: _selectedProvince,
        selectedDistrict: _selectedDistrict,
        onSelected: (province, district) {
          setState(() {
            _selectedProvince = province;
            _selectedDistrict = district;
          });
          _loadNeighborhoodData();
        },
      ),
    );
  }
}

// Location Picker Bottom Sheet
class _LocationPickerSheet extends StatefulWidget {
  final String selectedProvince;
  final String selectedDistrict;
  final Function(String, String) onSelected;

  const _LocationPickerSheet({
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.onSelected,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late String _province;
  late String _district;

  @override
  void initState() {
    super.initState();
    _province = widget.selectedProvince;
    _district = widget.selectedDistrict;
  }

  @override
  Widget build(BuildContext context) {
    final districts = TurkeyData.districts[_province] ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Konum Seç', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 20),
          const Text('İl', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _province,
            decoration: const InputDecoration(),
            items: TurkeyData.provinces.map((p) =>
              DropdownMenuItem(value: p, child: Text(p))
            ).toList(),
            onChanged: (v) => setState(() {
              _province = v!;
              _district = TurkeyData.districts[v]?.first ?? '';
            }),
          ),
          const SizedBox(height: 16),
          if (districts.isNotEmpty) ...[
            const Text('İlçe', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: districts.contains(_district) ? _district : districts.first,
              decoration: const InputDecoration(),
              items: districts.map((d) =>
                DropdownMenuItem(value: d, child: Text(d))
              ).toList(),
              onChanged: (v) => setState(() => _district = v!),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelected(_province, _district);
                Navigator.pop(context);
              },
              child: const Text('Uygula'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


// ─── AI Asistan Widget ───────────────────────────────────────────────────────
class _AIAssistantView extends StatefulWidget {
  final String neighborhood;
  final String district;

  const _AIAssistantView({
    required this.neighborhood,
    required this.district,
  });

  @override
  State<_AIAssistantView> createState() => _AIAssistantViewState();
}

class _AIAssistantViewState extends State<_AIAssistantView> {
  final _aiService = AIService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _msgCtrl.clear();
    _scroll();

    final reply = await _aiService.chatWithCitizen(
      question: text,
      neighborhood: widget.neighborhood,
      history: _messages.sublist(0, _messages.length - 1),
    );

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _loading = false;
    });
    _scroll();
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF0D2137)],
            ),
          ),
          child: Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mahalle Asistanı',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(
                    widget.neighborhood.isEmpty
                        ? widget.district
                        : widget.neighborhood,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Mesajlar
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) return _buildTyping();
                    final msg = _messages[i];
                    final isUser = msg['role'] == 'user';
                    return _buildBubble(msg['content']!, isUser);
                  },
                ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Mahalleniz hakkında soru sorun...',
                    hintStyle:
                        const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      'En yakın park nerede?',
      'Çöp toplama saatleri neler?',
      'Mahallede güvenlik nasıl?',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Mahalleniz hakkında ne öğrenmek istersiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            ...suggestions.map((s) => GestureDetector(
                  onTap: () {
                    _msgCtrl.text = s;
                    _send();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 4)
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: const Radius.circular(4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypingDot(delay: 0),
            SizedBox(width: 4),
            _TypingDot(delay: 150),
            SizedBox(width: 4),
            _TypingDot(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
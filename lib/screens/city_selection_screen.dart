// lib/screens/city_selection_screen.dart
// ŞehirSes — Şehir Seçim Ekranı
// Kullanıcı şehir seçer → harita ekranına geçer

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  final bool isFirstTime;
  const CitySelectionScreen({super.key, this.isFirstTime = false});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedCity;

  static const _featuredCities = [
    _CityOption(name: 'İstanbul',  emoji: '🌉', desc: 'Avrupa yakası, Anadolu yakası...'),
    _CityOption(name: 'Ankara',    emoji: '🏛',  desc: 'Çankaya\'dan Keçiören\'e kadar'),
    _CityOption(name: 'İzmir',     emoji: '🌊',  desc: 'Kordon, Alsancak ve daha fazlası'),
    _CityOption(name: 'Bursa',     emoji: '🏔',  desc: 'Osmangazi, Nilüfer ve Yıldırım'),
    _CityOption(name: 'Antalya',   emoji: '☀️',  desc: 'Muratpaşa, Kepez ve sahil semtleri'),
    _CityOption(name: 'Gaziantep', emoji: '🧆',  desc: 'Şahinbey, Şehitkamil ve ilçeler'),
  ];

  static const _allCities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya',
    'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir',
    'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu',
    'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli',
    'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum',
    'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay',
    'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş', 'Karabük',
    'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kilis', 'Kırıkkale',
    'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya',
    'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde',
    'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop',
    'Sivas', 'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon',
    'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
  ];

  List<String> get _filtered {
    if (_query.isEmpty) return _allCities;
    final q = _query.toLowerCase();
    return _allCities.where((c) => c.toLowerCase().contains(q)).toList();
  }

  void _select(String city) async {
    setState(() => _selectedCity = city);

    // SharedPreferences'a kaydet — main.dart ilk açılış kontrolü bunu okur
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_city', city);

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          if (_query.isEmpty) ...[
            _buildSectionTitle('🔥 Öne Çıkan Şehirler'),
            _buildFeaturedGrid(),
            _buildSectionTitle('📍 Tüm Şehirler'),
          ],
          _buildSearchBar(),
          _buildCityList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isFirstTime)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
              ),
            const SizedBox(height: 8),
            Text(
              widget.isFirstTime ? 'Şehrinizi Seçin' : 'Şehir Değiştir',
              style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: -1,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              'Hangi şehrin mahallelerini keşfetmek istiyorsunuz?',
              style: TextStyle(
                fontSize: 15, color: Colors.white.withOpacity(0.65),
              ),
            ).animate(delay: 150.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Şehir ara...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _FeaturedCityCard(
            city: _featuredCities[i],
            isSelected: _selectedCity == _featuredCities[i].name,
            onTap: () => _select(_featuredCities[i].name),
          ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.2, end: 0),
          childCount: _featuredCities.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
      ),
    );
  }

  Widget _buildCityList() {
    final cities = _filtered;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final city = cities[i];
            final isSelected = _selectedCity == city;
            return ListTile(
              onTap: () => _select(city),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: isSelected
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.transparent,
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🏙', style: TextStyle(fontSize: 20)),
                ),
              ),
              title: Text(
                city,
                style: TextStyle(
                 color: isSelected ? AppColors.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF27AE60))
                  : Icon(Icons.chevron_right,
                      color: Colors.white.withOpacity(0.3)),
            );
          },
          childCount: cities.length,
        ),
      ),
    );
  }
}

class _CityOption {
  final String name;
  final String emoji;
  final String desc;

  const _CityOption({
    required this.name,
    required this.emoji,
    required this.desc,
  });
}

class _FeaturedCityCard extends StatelessWidget {
  final _CityOption city;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeaturedCityCard({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF27AE60) : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? const Color(0xFF27AE60).withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(city.emoji, style: const TextStyle(fontSize: 28)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.name,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF2ECC71) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  city.desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

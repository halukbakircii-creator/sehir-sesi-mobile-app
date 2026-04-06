import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  final bool isFirstTime;
  final Function(String province, String district)? onSelected;
  const CitySelectionScreen({super.key, required this.isFirstTime, this.onSelected});
  @override State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  String? _province;
  String? _district;
  final _searchCtrl = TextEditingController();
  final MapController _mapCtrl = MapController();

  // Türkiye şehirlerinin koordinatları
  static const Map<String, LatLng> _cityCoords = {
    'Adana':          LatLng(37.0000, 35.3213),
    'Adıyaman':       LatLng(37.7648, 38.2786),
    'Afyonkarahisar': LatLng(38.7507, 30.5567),
    'Ağrı':           LatLng(39.7191, 43.0503),
    'Aksaray':        LatLng(38.3687, 34.0370),
    'Amasya':         LatLng(40.6499, 35.8353),
    'Ankara':         LatLng(39.9334, 32.8597),
    'Antalya':        LatLng(36.8969, 30.7133),
    'Ardahan':        LatLng(41.1105, 42.7022),
    'Artvin':         LatLng(41.1828, 41.8183),
    'Aydın':          LatLng(37.8444, 27.8458),
    'Balıkesir':      LatLng(39.6484, 27.8826),
    'Bartın':         LatLng(41.6344, 32.3375),
    'Batman':         LatLng(37.8812, 41.1351),
    'Bayburt':        LatLng(40.2552, 40.2249),
    'Bilecik':        LatLng(40.1506, 29.9792),
    'Bingöl':         LatLng(38.8854, 40.4983),
    'Bitlis':         LatLng(38.4006, 42.1095),
    'Bolu':           LatLng(40.7359, 31.6061),
    'Burdur':         LatLng(37.7260, 30.2876),
    'Bursa':          LatLng(40.1826, 29.0665),
    'Çanakkale':      LatLng(40.1553, 26.4142),
    'Çankırı':        LatLng(40.6013, 33.6134),
    'Çorum':          LatLng(40.5506, 34.9556),
    'Denizli':        LatLng(37.7765, 29.0864),
    'Diyarbakır':     LatLng(37.9144, 40.2306),
    'Düzce':          LatLng(40.8438, 31.1565),
    'Edirne':         LatLng(41.6818, 26.5623),
    'Elazığ':         LatLng(38.6810, 39.2264),
    'Erzincan':       LatLng(39.7500, 39.5000),
    'Erzurum':        LatLng(39.9000, 41.2700),
    'Eskişehir':      LatLng(39.7767, 30.5206),
    'Gaziantep':      LatLng(37.0662, 37.3833),
    'Giresun':        LatLng(40.9128, 38.3895),
    'Gümüşhane':      LatLng(40.4386, 39.4814),
    'Hakkari':        LatLng(37.5744, 43.7408),
    'Hatay':          LatLng(36.4018, 36.3498),
    'Iğdır':          LatLng(39.9167, 44.0333),
    'Isparta':        LatLng(37.7648, 30.5566),
    'İstanbul':       LatLng(41.0082, 28.9784),
    'İzmir':          LatLng(38.4237, 27.1428),
    'Kahramanmaraş':  LatLng(37.5858, 36.9371),
    'Karabük':        LatLng(41.2061, 32.6204),
    'Karaman':        LatLng(37.1759, 33.2287),
    'Kars':           LatLng(40.6013, 43.0975),
    'Kastamonu':      LatLng(41.3887, 33.7827),
    'Kayseri':        LatLng(38.7312, 35.4787),
    'Kilis':          LatLng(36.7184, 37.1212),
    'Kırıkkale':      LatLng(39.8468, 33.5153),
    'Kırklareli':     LatLng(41.7333, 27.2167),
    'Kırşehir':       LatLng(39.1425, 34.1709),
    'Kocaeli':        LatLng(40.8533, 29.8815),
    'Konya':          LatLng(37.8746, 32.4932),
    'Kütahya':        LatLng(39.4167, 29.9833),
    'Malatya':        LatLng(38.3552, 38.3095),
    'Manisa':         LatLng(38.6191, 27.4289),
    'Mardin':         LatLng(37.3212, 40.7245),
    'Mersin':         LatLng(36.8000, 34.6333),
    'Muğla':          LatLng(37.2153, 28.3636),
    'Muş':            LatLng(38.7432, 41.5064),
    'Nevşehir':       LatLng(38.6939, 34.6857),
    'Niğde':          LatLng(37.9667, 34.6833),
    'Ordu':           LatLng(40.9862, 37.8797),
    'Osmaniye':       LatLng(37.0742, 36.2464),
    'Rize':           LatLng(41.0201, 40.5234),
    'Sakarya':        LatLng(40.6940, 30.4358),
    'Samsun':         LatLng(41.2867, 36.3300),
    'Siirt':          LatLng(37.9333, 41.9500),
    'Sinop':          LatLng(42.0231, 35.1531),
    'Sivas':          LatLng(39.7477, 37.0179),
    'Şanlıurfa':      LatLng(37.1591, 38.7969),
    'Şırnak':         LatLng(37.4187, 42.4918),
    'Tekirdağ':       LatLng(40.9781, 27.5115),
    'Tokat':          LatLng(40.3167, 36.5500),
    'Trabzon':        LatLng(41.0015, 39.7178),
    'Tunceli':        LatLng(39.1079, 39.5480),
    'Uşak':           LatLng(38.6823, 29.4082),
    'Van':            LatLng(38.4891, 43.4089),
    'Yalova':         LatLng(40.6500, 29.2667),
    'Yozgat':         LatLng(39.8181, 34.8147),
    'Zonguldak':      LatLng(41.4564, 31.7987),
  };

  LatLng get _currentCoord =>
      _province != null ? (_cityCoords[_province] ?? const LatLng(39.0, 35.0))
                        : const LatLng(39.0, 35.0);

  double get _zoom => _province != null ? 10.0 : 5.5;

  static const _popularCities = [
    'Gaziantep','İstanbul','Ankara','İzmir','Bursa','Antalya','Adana','Konya'];

  List<String> get _districts =>
      _province != null ? (TurkeyData.districts[_province] ?? []) : [];

  List<String> get _filteredProvinces {
    final q = _searchCtrl.text.toLowerCase();
    return q.isEmpty ? TurkeyData.provinces
        : TurkeyData.provinces.where((p) => p.toLowerCase().contains(q)).toList();
  }

  Future<void> _apply() async {
    if (_province == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen il ve ilçe seçin'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_city', _province!);
    await prefs.setString('selected_district', _district!);
    if (widget.onSelected != null) {
      widget.onSelected!(_province!, _district!);
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => session != null ? const HomeScreen() : const LoginScreen()),
    );
  }

  void _selectProvince(String p) {
    setState(() { _province = p; _district = null; });
    // Haritayı şehre odakla
    Future.delayed(const Duration(milliseconds: 100), () {
      final coord = _cityCoords[p] ?? const LatLng(39.0, 35.0);
      _mapCtrl.move(coord, 10.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgContent,
      body: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const AppTicker(messages: [
          '🗺️ Türkiye genelinde 81 il kapsanıyor',
          '📍 Konumunuzu seçin, mahallenizi keşfedin',
        ]),
        _buildHeader(),
        Expanded(child: _buildContent()),
      ]),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16,
            MediaQuery.of(context).padding.bottom + 12),
        color: AppColors.bg,
        child: WhiteFab(
          label: 'Konumu Uygula', icon: '🗺️', onPressed: _apply),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        gradient: RadialGradient(center: const Alignment(0, -1), radius: 1.5,
          colors: [AppColors.purple.withOpacity(.14), AppColors.bg]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (!widget.isFirstTime) const AppBackButton(),
          if (!widget.isFirstTime) const SizedBox(width: 12),
          Text('Konumunuz', style: AppText.serif(26)),
          const Spacer(),
        ]),
        const SizedBox(height: 6),
        Text('Şehir ve ilçenizi seçin',
            style: AppText.sans(13, color: AppColors.text3)),
        const SizedBox(height: 14),
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          style: AppText.sans(14),
          decoration: const InputDecoration(
            hintText: 'İl ara...',
            prefixIcon: Icon(Icons.search, color: AppColors.text3, size: 20),
            isDense: true),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _chip('İl', _province, AppColors.purple)),
          const SizedBox(width: 10),
          Expanded(child: _chip('İlçe', _district, AppColors.teal)),
        ]),
      ]),
    );
  }

  Widget _chip(String label, String? value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value != null
            ? color.withOpacity(.1) : Colors.white.withOpacity(.03),
        border: Border.all(color: value != null
            ? color.withOpacity(.3) : Colors.white.withOpacity(.07)),
        borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: AppText.label(color: value != null
                ? color.withOpacity(.6) : AppColors.text3)),
        const SizedBox(height: 4),
        Text(value ?? 'Seçin...', style: GoogleFonts.manrope(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: value != null ? color : AppColors.text3.withOpacity(.5))),
      ]),
    );
  }

  Widget _buildContent() {
    if (_searchCtrl.text.isNotEmpty) {
      return _buildProvinceList(_filteredProvinces);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        // Gerçek OpenStreetMap haritası
        _buildMap(),
        const SizedBox(height: 16),
        const SectionLabel('Popüler Şehirler'),
        Wrap(spacing: 8, runSpacing: 8, children: _popularCities.map((city) {
          final sel = _province == city;
          return GestureDetector(
            onTap: () => _selectProvince(city),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? AppColors.purple.withOpacity(.15) : Colors.white.withOpacity(.04),
                border: Border.all(color: sel
                    ? AppColors.purple.withOpacity(.35) : Colors.white.withOpacity(.08)),
                borderRadius: BorderRadius.circular(10)),
              child: Text(city, style: GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: sel ? AppColors.purpleLight : AppColors.text3)),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),

        if (_province != null && _districts.isNotEmpty) ...[
          SectionLabel('$_province İlçeleri'),
          ..._districts.map((d) {
            final sel = _district == d;
            return GestureDetector(
              onTap: () => setState(() => _district = d),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? AppColors.teal.withOpacity(.08) : Colors.white.withOpacity(.03),
                  border: Border.all(color: sel
                      ? AppColors.teal.withOpacity(.3) : Colors.white.withOpacity(.07)),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(d, style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: sel ? AppColors.teal : AppColors.text2)),
                  if (sel) const Icon(Icons.check_circle_rounded,
                      color: AppColors.teal, size: 18),
                ]),
              ),
            );
          }),
        ] else if (_province != null && _districts.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.03),
              border: Border.all(color: Colors.white.withOpacity(.07)),
              borderRadius: BorderRadius.circular(12)),
            child: Text('$_province için ilçe verisi yükleniyor...',
                style: AppText.sans(13, color: AppColors.text3)),
          ),
        ] else ...[
          const SectionLabel('Tüm İller'),
          ..._filteredProvinces.map((p) => GestureDetector(
            onTap: () => _selectProvince(p),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.03),
                border: Border.all(color: Colors.white.withOpacity(.06)),
                borderRadius: BorderRadius.circular(10)),
              child: Text(p, style: AppText.sans(14, weight: FontWeight.w600)),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _currentCoord,
            initialZoom: _zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            // OpenStreetMap tile layer — ücretsiz
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sehirsesi.app',
            ),
            // Seçili şehirde marker
            if (_province != null && _cityCoords.containsKey(_province))
              MarkerLayer(markers: [
                Marker(
                  point: _cityCoords[_province]!,
                  width: 40, height: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryBtn,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: AppColors.purple.withOpacity(.5),
                            blurRadius: 12)],
                        ),
                        child: const Center(child: Text('📍',
                            style: TextStyle(fontSize: 18))),
                      ),
                    ],
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceList(List<String> provinces) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provinces.length,
      itemBuilder: (_, i) {
        final p = provinces[i];
        final sel = _province == p;
        return GestureDetector(
          onTap: () {
            _selectProvince(p);
            _searchCtrl.clear();
            setState(() {});
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: sel ? AppColors.purple.withOpacity(.08) : Colors.white.withOpacity(.03),
              border: Border.all(color: sel
                  ? AppColors.purple.withOpacity(.3) : Colors.white.withOpacity(.06)),
              borderRadius: BorderRadius.circular(12)),
            child: Text(p, style: GoogleFonts.manrope(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: sel ? AppColors.purpleLight : AppColors.text2)),
          ),
        );
      },
    );
  }
}

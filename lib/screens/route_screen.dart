// lib/screens/route_screen.dart
// ŞehirSes — Rota Öneri Ekranı

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/place_models.dart';
import '../services/route_service.dart';
import '../services/auth_service.dart';
import '../services/places_service.dart';
import '../theme/app_theme.dart';

class RouteScreen extends StatefulWidget {
  final String neighborhood;
  final String district;
  final String province;

  const RouteScreen({
    super.key,
    required this.neighborhood,
    required this.district,
    required this.province,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _routeService = RouteService();
  final _placesService = PlacesService();

  RouteType _selectedType = RouteType.quickWalk;
  RecommendedRoute? _route;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(children: [
          const Text('Rota Oluştur',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          Text(widget.neighborhood,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ]),
        leading: BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildGenerateButton(),
            const SizedBox(height: 24),
            if (_loading) _buildLoading(),
            if (_error != null) _buildError(),
            if (_route != null) _buildRouteResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ne tür bir gezi planlıyorsunuz?',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: RouteType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedType = type;
                _route = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isSelected ? AppColors.primaryLight : Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryLight : Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '~${type.estimatedDuration.inMinutes} dk',
                      style: TextStyle(
                        color: Colors.white.withOpacity(isSelected ? 0.85 : 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _generate,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI ile Rota Oluştur', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF27AE60)),
          const SizedBox(height: 16),
          Text(
            'AI rotanızı oluşturuyor...',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74C3C)),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildRouteResult() {
    final route = _route!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Özet kartı
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _routeBadge('${route.stops.length} durak'),
                  const SizedBox(width: 8),
                  _routeBadge('${route.totalDuration.inMinutes} dk'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                route.aiSummary,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.3, end: 0),

        const SizedBox(height: 24),
        const Text(
          'Duraklar',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        // Durak listesi
        ...route.stops.asMap().entries.map((entry) {
          final i    = entry.key;
          final stop = entry.value;
          final isLast = i == route.stops.length - 1;
          return _buildStopCard(stop, i, isLast)
              .animate(delay: (i * 80).ms)
              .fadeIn()
              .slideX(begin: 0.2, end: 0);
        }),

        const SizedBox(height: 20),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildStopCard(RouteStop stop, int index, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zaman çizelgesi
          Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: stop.place.category.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 40, color: Colors.white.withOpacity(0.15)),
            ],
          ),
          const SizedBox(width: 14),
          // Kart
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(stop.place.category.icon,
                          color: stop.place.category.color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        stop.place.category.label,
                        style: TextStyle(
                          color: stop.place.category.color,
                          fontSize: 11, fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '~${stop.suggestedTime.inMinutes} dk',
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stop.place.name,
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15,
                    ),
                  ),
                  if (stop.place.address != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      stop.place.address!,
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                    ),
                  ],
                  if (stop.tip != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stop.tip!,
                              style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSaveButton() {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Rotayı kaydetmek için giriş yapın',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Giriş Yap',
                  style: TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saveRoute,
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('Rotayı Kaydet'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF27AE60),
          side: const BorderSide(color: Color(0xFF27AE60)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── AKSIYONLAR ───────────────────────────────────────────────

  Future<void> _generate() async {
    setState(() { _loading = true; _error = null; _route = null; });
    try {
      final route = await _routeService.buildRoute(
        neighborhood: widget.neighborhood,
        district:     widget.district,
        province:     widget.province,
        type:         _selectedType,
      );
      setState(() { _route = route; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'Rota oluşturulamadı. Lütfen tekrar deneyin.';
        _loading = false;
      });
    }
  }

  Future<void> _saveRoute() async {
    if (_route == null) return;
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;

    final stops = _route!.stops.map((s) => {
      'place_id': s.place.id,
      'place_name': s.place.name,
      'order': s.orderIndex,
      'suggested_minutes': s.suggestedTime.inMinutes,
    }).toList();

    try {
      await _placesService.saveItinerary(
        userId:       auth.currentUser!.id,
        name:         _route!.name,
        neighborhood: widget.neighborhood,
        province:     widget.province,
        stops:        stops,
        aiSummary:    _route!.aiSummary,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rota kaydedildi!'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydetme başarısız.')),
        );
      }
    }
  }
}

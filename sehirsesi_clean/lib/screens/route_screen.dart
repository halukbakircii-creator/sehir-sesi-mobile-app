import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});
  @override State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  String _mode = 'walking'; // walking, driving, transit

  static const _tickerMessages = [
    '🧭 En güvenli rotayı buluyoruz',
    '🚶 Puan bazlı mahalle rotası',
    '🗺️ Gerçek zamanlı rota güncelleme',
  ];

  final _steps = [
    {'title': 'Şahinbey Merkez', 'sub': 'Başlangıç noktası', 'color': AppColors.purple, 'isStart': true},
    {'title': 'Mücahitler Cad.', 'sub': '1.2 km · Puan: 74', 'color': AppColors.purpleLight, 'isStart': false},
    {'title': 'Bağlarbaşı', 'sub': 'Varış · Puan: 88 ⭐', 'color': AppColors.teal, 'isStart': false},
  ];

  final _alternatives = [
    {'label': 'En Güvenli', 'km': '2.4', 'min': '28', 'score': 88, 'color': AppColors.green},
    {'label': 'En Kısa', 'km': '1.8', 'min': '22', 'score': 64, 'color': AppColors.amber},
    {'label': 'Yaya Dostu', 'km': '3.1', 'min': '36', 'score': 82, 'color': AppColors.teal},
  ];

  int _selectedRoute = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgContent,
      body: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const AppTicker(messages: _tickerMessages),
        _buildHeader(),
        Expanded(child: _buildContent()),
      ]),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
        color: AppColors.bg,
        child: WhiteFab(label: 'Navigasyonu Başlat', icon: '🧭', onPressed: () {}),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bg,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
          decoration: BoxDecoration(
            color: AppColors.bg,
            gradient: RadialGradient(center: const Alignment(.5, -1), radius: 1.5,
              colors: [AppColors.teal.withOpacity(.1), AppColors.bg]),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const AppBackButton(),
              Text('Rota Planlayıcı', style: AppText.serif(18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.purple.withOpacity(.1), border: Border.all(color: AppColors.purple.withOpacity(.2)), borderRadius: BorderRadius.circular(8)),
                child: Text('Filtre', style: AppText.sans(11, color: AppColors.purpleLight, weight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 14),
            _buildMapPlaceholder(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.02),
        border: Border.all(color: Colors.white.withOpacity(.07)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
        ),
        // Glow center
        Center(child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppColors.purple.withOpacity(.15), Colors.transparent])))),
        // Route line (custom paint)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CustomPaint(painter: _RoutePainter(), child: const SizedBox.expand()),
        ),
        // Route dots
        Positioned(left: 60, top: 130, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.purple, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(.5), blurRadius: 8)]))),
        Positioned(left: 165, top: 80, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: AppColors.purpleLight.withOpacity(.7), shape: BoxShape.circle))),
        Positioned(right: 70, top: 40, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(.5), blurRadius: 8)]))),
        // Labels
        Positioned(bottom: 12, left: 12, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.07), border: Border.all(color: Colors.white.withOpacity(.12)), borderRadius: BorderRadius.circular(8)),
          child: Text('Şahinbey → Bağlarbaşı', style: AppText.sans(9.5, color: AppColors.text2, weight: FontWeight.w600)),
        )),
        Positioned(top: 12, right: 12, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: AppColors.green.withOpacity(.12), border: Border.all(color: AppColors.green.withOpacity(.3)), borderRadius: BorderRadius.circular(8)),
          child: Text('EN GÜVENLİ', style: AppText.label(color: AppColors.green)),
        )),
      ]),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        // Mod seçimi
        _buildModeSelector(),
        const SizedBox(height: 16),
        // Rota alternatifleri
        const SectionLabel('Rota Seçenekleri'),
        ..._alternatives.asMap().entries.map((e) => _routeOption(e.key, e.value)),
        const SizedBox(height: 8),
        // Bilgi kartları
        const SectionLabel('Seçili Rota'),
        Row(children: [
          Expanded(child: _infoCard('2.4', 'KM', AppColors.purpleLight)),
          const SizedBox(width: 10),
          Expanded(child: _infoCard('28', 'DAK.', AppColors.teal)),
          const SizedBox(width: 10),
          Expanded(child: _infoCard('88', 'PUAN', AppColors.green)),
        ]),
        const SizedBox(height: 16),
        // Adımlar
        const SectionLabel('Rota Adımları'),
        _buildSteps(),
      ],
    );
  }

  Widget _buildModeSelector() {
    final modes = [
      {'key': 'walking', 'icon': '🚶', 'label': 'Yürüyüş'},
      {'key': 'driving', 'icon': '🚗', 'label': 'Araç'},
      {'key': 'transit', 'icon': '🚌', 'label': 'Toplu'},
    ];
    return Row(children: modes.map((m) {
      final selected = _mode == m['key'];
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _mode = m['key'] as String),
        child: Container(
          margin: EdgeInsets.only(right: m['key'] == 'transit' ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple.withOpacity(.12) : Colors.white.withOpacity(.03),
            border: Border.all(color: selected ? AppColors.purple.withOpacity(.3) : Colors.white.withOpacity(.07)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text(m['icon'] as String, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(m['label'] as String, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700,
              color: selected ? AppColors.purpleLight : AppColors.text3)),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _routeOption(int idx, Map m) {
    final selected = _selectedRoute == idx;
    final color = m['color'] as Color;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoute = idx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.07) : Colors.white.withOpacity(.03),
          border: Border.all(color: selected ? color.withOpacity(.3) : Colors.white.withOpacity(.07)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle,
            boxShadow: selected ? [BoxShadow(color: color.withOpacity(.5), blurRadius: 6)] : [])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m['label'] as String, style: AppText.sans(13, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('${m['km']} km · ${m['min']} dk', style: AppText.sans(11, color: AppColors.text3)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Puan ${m['score']}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ),
          if (selected) ...[const SizedBox(width: 8), Icon(Icons.check_circle_rounded, color: color, size: 18)],
        ]),
      ),
    );
  }

  Widget _infoCard(String val, String lbl, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.03), border: Border.all(color: Colors.white.withOpacity(.06)), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Text(val, style: GoogleFonts.playfairDisplay(fontSize: 22, color: color, letterSpacing: -1, height: 1)),
      const SizedBox(height: 5),
      Text(lbl, style: AppText.label()),
    ]),
  );

  Widget _buildSteps() {
    return Column(
      children: _steps.asMap().entries.map((e) {
        final step = e.value;
        final isLast = e.key == _steps.length - 1;
        final color = step['color'] as Color;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(.5), blurRadius: 8)])),
            if (!isLast) Container(width: 2, height: 40, color: Colors.white.withOpacity(.07)),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step['title'] as String, style: AppText.sans(13, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(step['sub'] as String, style: AppText.sans(11, color: AppColors.text3)),
            ]),
          )),
        ]);
      }).toList(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(.07)..strokeWidth = .3;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.purple.withOpacity(.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .17, size.height * .73)
      ..quadraticBezierTo(size.width * .4, size.height * .35, size.width * .5, size.height * .47)
      ..quadraticBezierTo(size.width * .65, size.height * .6, size.width * .83, size.height * .23);

    // Dashed
    const dashWidth = 8.0, dashSpace = 5.0;
    double distance = 0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final start = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(start, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }
  @override bool shouldRepaint(_) => false;
}

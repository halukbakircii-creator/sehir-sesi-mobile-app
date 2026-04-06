import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── RENKLER ────────────────────────────────────────────────────
class AppColors {
  static const Color bg          = Color(0xFF060608);
  static const Color bgContent   = Color(0xFF0A0B12);
  static const Color bgCard      = Color(0xFF0F1018);
  static const Color surface     = Color(0xFF141520);
  static const Color purple      = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleDark  = Color(0xFF7C3AED);
  static const Color purpleDim   = Color(0xFF1A1040);
  static const Color tickerBg    = Color(0xFF1a0533);
  static const Color tickerBg2   = Color(0xFF2d0a5e);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color text1       = Color(0xFFF1F5F9);
  static const Color text2       = Color(0xFF94A3B8);
  static const Color text3       = Color(0xFF475569);
  static const Color border      = Color(0xFF1E2030);
  static const Color green       = Color(0xFF4ADE80);
  static const Color teal        = Color(0xFF38BDF8);
  static const Color orange      = Color(0xFFFB923C);
  static const Color pink        = Color(0xFFF472B6);
  static const Color cyan        = Color(0xFF34D399);
  static const Color red         = Color(0xFFF87171);
  static const Color amber       = Color(0xFFFBBF24);
  static const Color catRoad      = Color(0xFFFB923C);
  static const Color catSecurity  = Color(0xFF38BDF8);
  static const Color catCleaning  = Color(0xFF4ADE80);
  static const Color catTransport = Color(0xFFC084FC);
  static const Color catPark      = Color(0xFF34D399);
  static const Color catSocial    = Color(0xFFF472B6);
  static const Color satisfied   = Color(0xFF4ADE80);
  static const Color neutral     = Color(0xFFFBBF24);
  static const Color unsatisfied = Color(0xFFF87171);

  // ─── ESKİ İSİMLER (home_screen.dart uyumluluğu için) ─────────
  static const Color primary       = Color(0xFF8B5CF6);
  static const Color secondary     = Color(0xFF38BDF8);
  static const Color accent        = Color(0xFF34D399);
  static const Color background    = Color(0xFF060608);
  static const Color cardBg        = Color(0xFF0F1018);
  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textLight     = Color(0xFF475569);
  static const Color noData        = Color(0xFF475569);
  static const Color cleaning      = Color(0xFF4ADE80);
  static const Color road          = Color(0xFFFB923C);
  static const Color security      = Color(0xFF38BDF8);
  static const Color park          = Color(0xFF34D399);
  static const Color transport     = Color(0xFFC084FC);
  static const Color social        = Color(0xFFF472B6);

}

// ─── GRADİENTLER ─────────────────────────────────────────────────
class AppGradients {
  static const LinearGradient primaryBtn = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF0EA5E9)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const LinearGradient cardPurple = LinearGradient(
    colors: [Color(0xFF1A1040), Color(0xFF0D0D1A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient ticker = LinearGradient(
    colors: [Color(0xFF1a0533), Color(0xFF2d0a5e), Color(0xFF1a0533)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const LinearGradient heroMesh = LinearGradient(
    colors: [Color(0xFF0A0B12), Color(0xFF060608)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
}

// ─── TEXT ────────────────────────────────────────────────────────
class AppText {
  static TextStyle serif(double size, {Color color = AppColors.text1, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontSize: size, color: color, fontWeight: weight);
  static TextStyle sans(double size, {Color color = AppColors.text1, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.manrope(fontSize: size, color: color, fontWeight: weight);
  static TextStyle label({Color color = AppColors.text3}) =>
      GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.0, color: color);
}

// ─── TEMA ─────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple, secondary: AppColors.teal,
      surface: AppColors.bgCard,
    ),
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg, foregroundColor: AppColors.text1,
      elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, color: AppColors.text1, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: AppColors.text2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white, foregroundColor: const Color(0xFF0A0A14),
        shadowColor: Colors.transparent, overlayColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.white, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 17),
        textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: .5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.bgCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
      labelStyle: GoogleFonts.manrope(color: AppColors.text3, fontSize: 12),
      hintStyle: GoogleFonts.manrope(color: AppColors.text3, fontSize: 14),
    ),
  );
}

// SatisfactionLevel ve getSatisfactionLevel → models.dart içinde tanımlı

// ─── SHARED WIDGETS ──────────────────────────────────────────────

/// Kayan haber bandı
class AppTicker extends StatefulWidget {
  final List<String> messages;
  const AppTicker({super.key, required this.messages});
  @override State<AppTicker> createState() => _AppTickerState();
}
class _AppTickerState extends State<AppTicker> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final fullText = widget.messages.map((m) => '  $m  ·').join('') * 2;
    return Container(
      height: 36,
      decoration: const BoxDecoration(gradient: AppGradients.ticker),
      child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, child: Container(height: .5, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.purpleLight.withOpacity(.7), Colors.transparent])))),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: .5, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.purpleLight.withOpacity(.35), Colors.transparent])))),
        Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 44, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.tickerBg, Colors.transparent])))),
        Positioned(right: 0, top: 0, bottom: 0, child: Container(width: 44, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.tickerBg])))),
        Align(alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => FractionalTranslation(translation: Offset(-_ctrl.value, 0), child: child),
            child: Text(fullText, maxLines: 1, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFFC4B5FD).withOpacity(.85), letterSpacing: .2)),
          ),
        ),
      ]),
    );
  }
}

/// Kategori pill
class CategoryPill extends StatelessWidget {
  final String icon;
  final String label;
  final double value;
  final Color color;
  const CategoryPill({super.key, required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.06), border: Border.all(color: Colors.white.withOpacity(.09)), borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text('$icon $label', overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(.75)))),
          const SizedBox(width: 4),
          Text(value.toStringAsFixed(0), style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w900, color: color, letterSpacing: -.3)),
        ]),
      ),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(value: value / 100, backgroundColor: Colors.white.withOpacity(.07), valueColor: AlwaysStoppedAnimation(color), minHeight: 3)),
    ]);
  }
}

/// Gradient buton
class GradientButton extends StatelessWidget {
  final String label;
  final String? icon;
  final VoidCallback onPressed;
  const GradientButton({super.key, required this.label, this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(gradient: AppGradients.primaryBtn, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Text(icon!, style: const TextStyle(fontSize: 16)), const SizedBox(width: 9)],
          Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .5)),
        ]),
      ),
    );
  }
}

/// Beyaz FAB buton
class WhiteFab extends StatelessWidget {
  final String label;
  final String? icon;
  final VoidCallback onPressed;
  const WhiteFab({super.key, required this.label, this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity,
      child: ElevatedButton(onPressed: onPressed,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Text(icon!, style: const TextStyle(fontSize: 16)), const SizedBox(width: 9)],
          Text(label),
        ]),
      ),
    );
  }
}

/// App kart
class AppCard extends StatelessWidget {
  final Widget child;
  final bool isPurple;
  final bool hasTealShine;
  final EdgeInsets? padding;
  const AppCard({super.key, required this.child, this.isPurple = false, this.hasTealShine = false, this.padding});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: isPurple ? AppGradients.cardPurple : null,
        color: isPurple ? null : Colors.white.withOpacity(.035),
        border: Border.all(color: isPurple ? AppColors.purple.withOpacity(.2) : Colors.white.withOpacity(.07)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18),
        child: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, child: Container(height: .5, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, (isPurple ? AppColors.purple : hasTealShine ? AppColors.teal : AppColors.purple).withOpacity(.7), Colors.transparent])))),
          Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ]),
      ),
    );
  }
}

/// Section label
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text.toUpperCase(), style: AppText.label()));
}

/// Live badge
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});
  @override State<LiveBadge> createState() => _LiveBadgeState();
}
class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true); _anim = Tween<double>(begin: 1, end: .3).animate(_ctrl); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: AppColors.green.withOpacity(.06), border: Border.all(color: AppColors.green.withOpacity(.15)), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(animation: _anim, builder: (_, __) => Container(width: 5, height: 5, decoration: BoxDecoration(color: AppColors.green.withOpacity(_anim.value), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.green.withOpacity(.8), blurRadius: 7)]))),
        const SizedBox(width: 5),
        Text('CANLI', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.green, letterSpacing: 1.5)),
      ]),
    );
  }
}

/// Stat box
class StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const StatBox({super.key, required this.value, required this.label, required this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.03), border: Border.all(color: Colors.white.withOpacity(.06)), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.playfairDisplay(fontSize: 24, letterSpacing: -1, color: valueColor, height: 1)),
        const SizedBox(height: 5),
        Text(label.toUpperCase(), style: AppText.label()),
      ]),
    );
  }
}

/// Back button
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.06), border: Border.all(color: Colors.white.withOpacity(.08)), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text2, size: 15),
      ),
    );
  }
}

/// FAB zone (alt gradient üzerinde beyaz buton)
class FabZone extends StatelessWidget {
  final String label;
  final String? icon;
  final VoidCallback onPressed;
  const FabZone({super.key, required this.label, this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppColors.bg.withOpacity(0), AppColors.bg, AppColors.bg]),
      ),
      child: WhiteFab(label: label, icon: icon, onPressed: onPressed),
    );
  }
}

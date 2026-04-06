import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'city_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl     = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  int _tab = 0; // 0=giriş, 1=kayıt
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  static const _tickerMessages = [
    '🔐 Güvenli giriş — email ve şifre',
    '🛡️ KVKK uyumlu · Verileriniz şifrelenir',
    '✅ Ücretsiz hesap oluşturun',
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── GİRİŞ YAP ───────────────────────────────────────────────
  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Email adresinizi girin');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final result = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final hasCity = (prefs.getString('selected_city') ?? '').isNotEmpty;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hasCity ? const HomeScreen() : const CitySelectionScreen(isFirstTime: true),
        ),
      );
    } else {
      setState(() {
        _error = result['error'] ?? 'Giriş başarısız';
        _loading = false;
      });
    }
  }

  // ─── KAYIT OL ────────────────────────────────────────────────
  Future<void> _register() async {
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Geçerli bir email adresi girin');
      return;
    }
    if (_usernameCtrl.text.trim().length < 3) {
      setState(() => _error = 'Kullanıcı adı en az 3 karakter olmalı');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final result = await auth.register(
      email: _emailCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CitySelectionScreen(isFirstTime: true)),
      );
    } else {
      setState(() {
        _error = result['error'] ?? 'Kayıt başarısız';
        _loading = false;
      });
    }
  }

  // ─── ŞİFRE SIFIRLAMA DİALOG ──────────────────────────────────
  void _showForgotPassword() {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Şifre Sıfırla', style: AppText.sans(16, weight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kayıtlı email adresinize şifre sıfırlama bağlantısı göndereceğiz.',
              style: AppText.sans(13, color: AppColors.text3),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                style: AppText.sans(14, weight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'ornek@email.com',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: AppText.sans(13, color: AppColors.text3)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isEmpty) return;
              final auth = context.read<AuthService>();
              final result = await auth.resetPassword(ctrl.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  result['success'] == true
                    ? '✅ Şifre sıfırlama maili gönderildi!'
                    : '❌ ${result['error']}',
                ),
                backgroundColor: result['success'] == true ? Colors.green : AppColors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: Text('Gönder', style: AppText.sans(13, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const AppTicker(messages: _tickerMessages),
        Expanded(child: SingleChildScrollView(child: Column(children: [
          _buildHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: _buildForm(),
          ),
        ]))),
      ]),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.bg,
        gradient: RadialGradient(
          center: Alignment.topCenter, radius: 1.2,
          colors: [AppColors.purple.withOpacity(.15), AppColors.bg],
        ),
      ),
      child: Column(children: [
        const Row(children: [
          AppBackButton(),
          Spacer(),
        ]),
        const SizedBox(height: 24),
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            gradient: AppGradients.cardPurple,
            border: Border.all(color: AppColors.purple.withOpacity(.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: Text('🔐', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 16),
        Text('ŞehirSesi', style: AppText.serif(28)),
        const SizedBox(height: 8),
        Text(
          _tab == 0 ? 'Hesabınıza giriş yapın' : 'Yeni hesap oluşturun',
          style: AppText.sans(13, color: AppColors.text3).copyWith(height: 1.65),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.04),
            border: Border.all(color: Colors.white.withOpacity(.08)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            _tabBtn(0, 'Giriş Yap'),
            _tabBtn(1, 'Kayıt Ol'),
          ]),
        ),
      ]),
    );
  }

  Widget _tabBtn(int idx, String label) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _tab = idx; _error = null; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.purple.withOpacity(.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: active ? Border.all(color: AppColors.purple.withOpacity(.4)) : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800,
              color: active ? AppColors.purpleLight : AppColors.text3)),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(children: [
      const SizedBox(height: 8),

      // Email alanı (her iki tab'da da var)
      _inputField(
        label: 'Email',
        hint: 'ornek@email.com',
        controller: _emailCtrl,
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),

      // Kullanıcı adı sadece kayıt tab'ında
      if (_tab == 1) ...[
        const SizedBox(height: 10),
        _inputField(
          label: 'Kullanıcı Adı',
          hint: 'kullanici_adi',
          controller: _usernameCtrl,
          icon: Icons.person_outline_rounded,
        ),
      ],

      const SizedBox(height: 10),
      _inputField(
        label: 'Şifre',
        hint: '••••••••',
        controller: _passwordCtrl,
        icon: Icons.lock_outline_rounded,
        isPassword: true,
      ),

      // Şifremi unuttum (sadece giriş tab'ında)
      if (_tab == 0)
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _showForgotPassword,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Şifremi Unuttum',
                style: AppText.sans(12, color: AppColors.purpleLight, weight: FontWeight.w700),
              ),
            ),
          ),
        ),

      if (_error != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(.08),
            border: Border.all(color: AppColors.red.withOpacity(.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: AppText.sans(12, color: AppColors.red))),
          ]),
        ),
      ],

      const SizedBox(height: 20),
      _loading
        ? const CircularProgressIndicator(color: AppColors.purple, strokeWidth: 2)
        : GradientButton(
            label: _tab == 0 ? 'Giriş Yap' : 'Kayıt Ol',
            icon: _tab == 0 ? '🚀' : '✨',
            onPressed: _tab == 0 ? _login : _register,
          ),

      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => setState(() { _tab = _tab == 0 ? 1 : 0; _error = null; }),
        child: Text(
          _tab == 0 ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap',
          style: AppText.sans(13, color: AppColors.purpleLight, weight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🛡️ KVKK Uyumlu', style: AppText.sans(10, color: AppColors.text3, weight: FontWeight.w600)),
        const SizedBox(width: 20),
        Text('🔒 Şifreli Bağlantı', style: AppText.sans(10, color: AppColors.text3, weight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: AppText.label()),
        const SizedBox(height: 6),
        Row(children: [
          Icon(icon, color: AppColors.text3, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              keyboardType: keyboardType,
              style: AppText.sans(15, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint, border: InputBorder.none,
                isDense: true, contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.text3, size: 18,
              ),
            ),
        ]),
      ]),
    );
  }
}

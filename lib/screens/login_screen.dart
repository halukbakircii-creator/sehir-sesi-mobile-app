// lib/screens/login_screen.dart (GÜNCELLENDİ - 2 Adımlı SMS OTP)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'address_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Adım 1
  final _tcController = TextEditingController();
  final _phoneController = TextEditingController();
  // Adım 2
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  int _step = 1; // 1 = TC+Telefon, 2 = OTP
  bool _obscureTC = true;
  int _resendSeconds = 0;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _tcController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  // ADIM 1: SMS gönder
  Future<void> _sendOTP() async {
    if (!AuthService.validateTCKimlik(_tcController.text)) {
      _showError('Geçersiz TC Kimlik Numarası');
      return;
    }
    if (_phoneController.text.length < 10) {
      _showError('Geçersiz telefon numarası');
      return;
    }

    final auth = context.read<AuthService>();
    final result = await auth.sendOTP(
      phone: _phoneController.text,
      tcKimlik: _tcController.text,
    );

    if (!mounted) return;
    if (result['success']) {
      setState(() => _step = 2);
      _startResendTimer();
      _slideCtrl.reset();
      _slideCtrl.forward();
      _otpFocusNodes[0].requestFocus();
    } else {
      _showError(result['error']);
    }
  }

  // ADIM 2: OTP doğrula
  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      _showError('6 haneli kodu eksiksiz girin');
      return;
    }

    final auth = context.read<AuthService>();

    // Adres seçimi için geçici değerler (sonraki ekranda düzenlenecek)
    final result = await auth.verifyOTP(
      otp: otp,
      tcKimlik: _tcController.text,
      province: 'Gaziantep',
      district: 'Şahinbey',
      neighborhood: 'Akkent',
    );

    if (!mounted) return;
    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AddressSetupScreen()),
      );
    } else {
      _showError(result['error']);
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
    }
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.unsatisfied,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF0D2137), Color(0xFF162B45)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 40),
                // Adım göstergesi
                _buildStepIndicator(),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _slideAnim,
                  child: _step == 1 ? _buildStep1() : _buildStep2(),
                ),
                const SizedBox(height: 20),
                _buildPrivacyNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: const Center(child: Text('🏙️', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 20),
        const Text('ŞehirSes', style: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w900,
          color: Colors.white, letterSpacing: -1,
        )),
        const SizedBox(height: 6),
        Text('Sesinizi duyurun. Şehrinizi şekillendirin.',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.65))),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [1, 2].map((s) {
        final active = s == _step;
        final done = s < _step;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 32 : 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.satisfied
                    : active ? Colors.white
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text('$s', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: active ? AppColors.primary : Colors.white60,
                    ))),
            ),
            if (s < 2)
              Container(
                width: 40, height: 2, margin: const EdgeInsets.symmetric(horizontal: 6),
                color: _step > s ? AppColors.satisfied : Colors.white.withOpacity(0.2),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kimliğini Doğrula', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
          )),
          const SizedBox(height: 4),
          Text('TC Kimlik + Telefon ile güvenli giriş', style: TextStyle(
            fontSize: 13, color: AppColors.textSecondary,
          )),
          const SizedBox(height: 24),

          // TC Kimlik
          _fieldLabel('TC Kimlik No'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tcController,
            obscureText: _obscureTC,
            keyboardType: TextInputType.number,
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '00000000000',
              counterText: '',
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscureTC ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary),
                onPressed: () => setState(() => _obscureTC = !_obscureTC),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Telefon
          _fieldLabel('Telefon Numarası'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '05XX XXX XX XX',
              counterText: '',
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
              prefix: Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('🇹🇷', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Consumer<AuthService>(
            builder: (ctx, auth, _) => SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _sendOTP,
                child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sms_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('SMS Kodu Gönder', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                          )),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final phone = _phoneController.text;
    final masked = phone.length >= 4
        ? '${phone.substring(0, 4)}***${phone.substring(phone.length - 2)}'
        : phone;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SMS Kodunu Girin', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
          )),
          const SizedBox(height: 4),
          Text('$masked numarasına 6 haneli kod gönderildi',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          // 6 haneli OTP kutuları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _buildOTPBox(i)),
          ),
          const SizedBox(height: 24),

          Consumer<AuthService>(
            builder: (ctx, auth, _) => SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _verifyOTP,
                child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Doğrula & Giriş Yap', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tekrar gönder
          Center(
            child: _resendSeconds > 0
                ? Text('Tekrar göndermek için $_resendSeconds sn bekleyin',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
                : GestureDetector(
                    onTap: () {
                      _sendOTP();
                      for (final c in _otpControllers) c.clear();
                    },
                    child: const Text('Kodu tekrar gönder',
                      style: TextStyle(
                        fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600,
                      )),
                  ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() => _step = 1);
                _slideCtrl.reset();
                _slideCtrl.forward();
              },
              child: Text('Geri dön',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return SizedBox(
      width: 44, height: 52,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          // 6 hane tamamsa otomatik doğrula
          final otp = _otpControllers.map((c) => c.text).join();
          if (otp.length == 6) _verifyOTP();
        },
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    ));
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.7), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'TC Kimlik bilginiz SHA-256 ile şifrelenir, asla ham halde saklanmaz. KVKK uyumludur.',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.5),
          )),
        ],
      ),
    );
  }
}

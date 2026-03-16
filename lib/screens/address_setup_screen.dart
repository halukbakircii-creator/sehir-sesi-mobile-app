// lib/screens/address_setup_screen.dart
// Giriş sonrası adres ayarlama ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AddressSetupScreen extends StatefulWidget {
  const AddressSetupScreen({super.key});

  @override
  State<AddressSetupScreen> createState() => _AddressSetupScreenState();
}

class _AddressSetupScreenState extends State<AddressSetupScreen> {
  String _selectedProvince = 'Gaziantep';
  String _selectedDistrict = 'Şahinbey';
  String? _selectedNeighborhood;
  bool _saving = false;

  List<String> get _districts =>
      TurkeyData.districts[_selectedProvince] ?? [];

  List<String> get _neighborhoods =>
      TurkeyData.neighborhoods[_selectedDistrict] ?? [];

  Future<void> _save() async {
    if (_selectedNeighborhood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen mahallenizi seçin')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Auth service üzerinden Supabase'e kaydet
      await context.read<AuthService>().updateAddress(
        province: _selectedProvince,
        district: _selectedDistrict,
        neighborhood: _selectedNeighborhood!,
      );

      // SharedPreferences'a da kaydet (app-wide seçili şehir)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_city', _selectedProvince);
      await prefs.setString('selected_district', _selectedDistrict);
      await prefs.setString('selected_neighborhood', _selectedNeighborhood!);

      if (!mounted) return;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text('📍', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 16),
                const Text(
                  'Adresinizi Belirleyin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mahallenize özel raporlar ve geri bildirimler için adresinizi girin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dropdownField(
                          label: 'İl',
                          value: _selectedProvince,
                          items: TurkeyData.provinces,
                          onChanged: (v) => setState(() {
                            _selectedProvince = v!;
                            _selectedDistrict = _districts.first;
                            _selectedNeighborhood = null;
                          }),
                        ),
                        const SizedBox(height: 16),
                        _dropdownField(
                          label: 'İlçe',
                          value: _selectedDistrict,
                          items: _districts,
                          onChanged: (v) => setState(() {
                            _selectedDistrict = v!;
                            _selectedNeighborhood = null;
                          }),
                        ),
                        const SizedBox(height: 16),
                        _dropdownField(
                          label: 'Mahalle',
                          value: _selectedNeighborhood,
                          hint: 'Mahalle seçin',
                          items: _neighborhoods,
                          onChanged: (v) =>
                              setState(() => _selectedNeighborhood = v),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Kaydet ve Devam Et',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : null,
          hint: Text(hint ?? label),
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

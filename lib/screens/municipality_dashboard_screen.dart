// lib/screens/municipality_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class MunicipalityDashboardScreen extends StatefulWidget {
  const MunicipalityDashboardScreen({super.key});

  @override
  State<MunicipalityDashboardScreen> createState() =>
      _MunicipalityDashboardScreenState();
}

class _MunicipalityDashboardScreenState extends State<MunicipalityDashboardScreen> {
  final _aiService = AIService();
  final _supabase = SupabaseService();
  String? _fullReport;
  bool _loadingReport = false;
  bool _loadingData = true;
  String _province = 'Gaziantep';

  List<Map<String, dynamic>> _districts = [];

  double _overallScore = 0;

  void _updateOverallScore() {
    if (_districts.isEmpty) { _overallScore = 0; return; }
    _overallScore = _districts
        .map((d) => (d['score'] as num).toDouble())
        .reduce((a, b) => a + b) / _districts.length;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Kullanıcının iline göre yükle
    final profile = context.read<AuthService>().profile;
    if (profile?['province'] != null) {
      _province = profile!['province'];
    }

    try {
      final data = await _supabase.getProvinceDistrictSummary(_province);
      setState(() {
        _districts = data.map((d) => {
          'name': d['district'],
          'score': (d['score'] as num).toDouble(),
          'feedbacks': d['feedbacks'],
        }).toList();
        _updateOverallScore();
        _loadingData = false;
      });
    } catch (_) {
      // Supabase bağlantı yoksa demo veri göster
      setState(() {
        _updateOverallScore();
        _districts = [
          {'name': 'Şahinbey', 'score': 72.5, 'feedbacks': 1240},
          {'name': 'Şehitkamil', 'score': 65.2, 'feedbacks': 980},
          {'name': 'Nizip', 'score': 58.8, 'feedbacks': 430},
          {'name': 'İslahiye', 'score': 81.3, 'feedbacks': 290},
          {'name': 'Nurdağı', 'score': 47.6, 'feedbacks': 180},
        ];
        _updateOverallScore();
        _loadingData = false;
      });
    }
  }

  Future<void> _generateFullReport() async {
    setState(() => _loadingReport = true);

    final criticalIssues = _districts
        .where((d) => (d['score'] as num) < 50)
        .map((d) => '${d['name']} ilçesinde memnuniyet kritik seviyede (%${(d['score'] as num).toStringAsFixed(0)})')
        .toList();

    if (criticalIssues.isEmpty) {
      criticalIssues.add('Genel olarak memnuniyet seviyeleri kabul edilebilir');
    }

    final report = await _aiService.generateMunicipalityReport(
      province: _province,
      overallScore: _overallScore,
      districtData: _districts,
      criticalIssues: criticalIssues,
    );
    if (!mounted) return;
    setState(() {
      _fullReport = report;
      _loadingReport = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildOverallScore(),
          const SizedBox(height: 16),
          _buildDistrictRanking(),
          const SizedBox(height: 16),
          _buildCategoryOverview(),
          const SizedBox(height: 16),
          _buildTrendChart(),
          const SizedBox(height: 16),
          _buildAIReportSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Belediye Paneli',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                "$_province Büyükşehir Belediyesi",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.refresh, size: 14, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Canlı Veri',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScore() {
    final level = getSatisfactionLevel(_overallScore);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A5C), Color(0xFF0D5F8A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Genel İl Skoru',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '%${_overallScore.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${level.emoji} ${level.label}',
                    style: TextStyle(
                      color: level.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _dashStat('${_districts.fold(0, (s, d) => s + (d['feedbacks'] as int))}', 'Toplam\nGeri Bildirim'),
              const SizedBox(height: 10),
              _dashStat('${_districts.length}', 'İlçe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashStat(String val, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(val, style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
          )),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(
            color: Colors.white60, fontSize: 10,
          )),
        ],
      ),
    );
  }

  Widget _buildDistrictRanking() {
    final sorted = [..._districts]
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 İlçe Sıralaması',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...sorted.asMap().entries.map((e) => _buildDistrictRow(e.key + 1, e.value)),
      ],
    );
  }

  Widget _buildDistrictRow(int rank, Map<String, dynamic> district) {
    final score = district['score'] as double;
    final level = getSatisfactionLevel(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? [Colors.amber, Colors.grey[400]!, Colors.brown[300]!][rank - 1]
                  : Colors.grey[100]!,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: rank <= 3 ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district['name'],
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  '${district['feedbacks']} geri bildirim',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '%${score.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: level.color,
                ),
              ),
              Container(
                width: 80,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: level.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOverview() {
    final categories = [
      {'cat': FeedbackCategory.cleaning, 'score': 68.0},
      {'cat': FeedbackCategory.road, 'score': 52.0},
      {'cat': FeedbackCategory.security, 'score': 74.0},
      {'cat': FeedbackCategory.park, 'score': 45.0},
      {'cat': FeedbackCategory.transport, 'score': 61.0},
      {'cat': FeedbackCategory.social, 'score': 70.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Kategori Analizi',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: categories.map((c) {
              final cat = c['cat'] as FeedbackCategory;
              final score = c['score'] as double;
              final pct = score / 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat.label, style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                              )),
                              Text('%${score.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: getSatisfactionLevel(score).color,
                                )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey[100],
                              valueColor: AlwaysStoppedAnimation(cat.color),
                              minHeight: 7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz'];
    final scores = [58.0, 62.0, 59.0, 65.0, 68.0, 71.5];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📈 6 Aylık Trend',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= 0 && i < months.length) {
                        return Text(months[i], style: const TextStyle(fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: scores.asMap().entries.map(
                    (e) => FlSpot(e.key.toDouble(), e.value),
                  ).toList(),
                  isCurved: true,
                  color: AppColors.secondary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.secondary.withOpacity(0.1),
                  ),
                ),
              ],
              minY: 40,
              maxY: 100,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🤖 AI Yönetici Raporu',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_fullReport != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _fullReport!,
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.05), Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                const Text('📋', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  'Belediye Başkanı için Yönetici Özeti',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tüm ilçelerin verilerini analiz eden, öncelikli eylem planı içeren kapsamlı AI raporu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadingReport ? null : _generateFullReport,
                    child: _loadingReport
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Rapor hazırlanıyor...'),
                            ],
                          )
                        : const Text('🤖 Rapor Oluştur'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

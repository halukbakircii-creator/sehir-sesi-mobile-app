// lib/screens/neighborhood_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import 'feedback_screen.dart';

class NeighborhoodDetailScreen extends StatefulWidget {
  final NeighborhoodStats stats;
  const NeighborhoodDetailScreen({super.key, required this.stats});

  @override
  State<NeighborhoodDetailScreen> createState() => _NeighborhoodDetailScreenState();
}

class _NeighborhoodDetailScreenState extends State<NeighborhoodDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _aiReport;
  bool _loadingReport = false;
  final _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _aiReport = widget.stats.aiReport;
  }

  Future<void> _generateAIReport() async {
    setState(() => _loadingReport = true);
    final report = await _aiService.generateNeighborhoodReport(widget.stats);
    setState(() {
      _aiReport = report;
      _loadingReport = false;
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.stats.satisfactionLevel;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: level.color,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.stats.neighborhood,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      level.color,
                      level.color.withOpacity(0.7),
                      AppColors.primary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        level.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '%${widget.stats.overallScore.toStringAsFixed(0)} Memnuniyet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.stats.totalFeedbacks} geri bildirim',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Özet'),
                  Tab(text: 'Kategoriler'),
                  Tab(text: 'AI Raporu'),
                ],
              ),
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSummaryTab(),
                _buildCategoriesTab(),
                _buildAIReportTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FeedbackScreen(
              preselectedNeighborhood: widget.stats.neighborhood,
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text(
          'Geri Bildirim Ver',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memnuniyet Göstergesi
          _buildSectionTitle('Genel Memnuniyet'),
          const SizedBox(height: 12),
          _buildScoreGauge(),
          const SizedBox(height: 20),

          // Sorunlar
          _buildSectionTitle('🔴 Öne Çıkan Sorunlar'),
          const SizedBox(height: 8),
          ...widget.stats.topIssues.map((issue) => _buildIssueItem(issue, isIssue: true)),
          const SizedBox(height: 20),

          // Olumlu
          _buildSectionTitle('🟢 Beğenilen Yönler'),
          const SizedBox(height: 8),
          ...widget.stats.topPraises.map((praise) => _buildIssueItem(praise, isIssue: false)),
        ],
      ),
    );
  }

  Widget _buildScoreGauge() {
    final score = widget.stats.overallScore;
    final level = widget.stats.satisfactionLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 16,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation(level.color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%${score.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      level.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: level.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _scoreMetric('${widget.stats.totalFeedbacks}', 'Geri Bildirim', Icons.comment_outlined),
              _scoreMetric(widget.stats.district, 'İlçe', Icons.location_on_outlined),
              _scoreMetric(widget.stats.province, 'İl', Icons.map_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreMetric(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bar chart
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: widget.stats.categoryScores.entries.toList().asMap().entries
                    .map((e) => BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value.clamp(0, 100),
                          color: e.value.key.color,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ))
                    .toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final cats = widget.stats.categoryScores.keys.toList();
                        if (v.toInt() < cats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(cats[v.toInt()].icon, size: 14),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Kategori detayları
          ...widget.stats.categoryScores.entries.map((e) =>
              _buildCategoryRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(FeedbackCategory cat, double score) {
    final pct = score.clamp(0, 100) / 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cat.icon, color: cat.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.label, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13,
                    )),
                    Text(
                      '%${score.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: getSatisfactionLevel(score).color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
  }

  Widget _buildAIReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Rapor başlığı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AI Analiz Raporu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Claude AI tarafından oluşturuldu',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_loadingReport)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI raporu hazırlanıyor...'),
                  ],
                ),
              ),
            )
          else if (_aiReport != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _aiReport!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          else
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    '📊',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Raporu Henüz Oluşturulmadı',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mahalle için detaylı AI analizi oluşturmak için butona tıklayın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _generateAIReport,
                    icon: const Text('🤖'),
                    label: const Text('Rapor Oluştur'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildIssueItem(String text, {required bool isIssue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isIssue
              ? AppColors.unsatisfied.withOpacity(0.3)
              : AppColors.satisfied.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isIssue ? Icons.warning_amber_outlined : Icons.check_circle_outline,
            color: isIssue ? AppColors.unsatisfied : AppColors.satisfied,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, _, __) => Container(
    color: Colors.white,
    child: tabBar,
  );

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(_) => false;
}

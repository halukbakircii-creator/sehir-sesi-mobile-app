// lib/services/filter_service.dart
// ŞehirSes — Filtre Durum Yöneticisi (ChangeNotifier)
//
// Kullanım:
//   ChangeNotifierProvider(create: (_) => FilterService(), ...)
//   context.watch<FilterService>().activeFilter

import 'package:flutter/foundation.dart';
import '../models/place_models.dart';
import '../models/models.dart';
import 'score_engine.dart';

class FilterService extends ChangeNotifier {
  // ── Aktif filtreler ──────────────────────────────────────────
  NeighborhoodFilter _activeFilter = NeighborhoodFilter.overall;
  final Set<PlaceCategoryType> _activePlaceCategories = {};
  String  _searchQuery     = '';
  double  _minScore        = 0;
  bool    _onlyTrending    = false;
  bool    _onlyHighSafety  = false;
  bool    _onlyFamilyFriendly = false;

  // ── Getters ──────────────────────────────────────────────────
  NeighborhoodFilter         get activeFilter          => _activeFilter;
  Set<PlaceCategoryType>     get activePlaceCategories => _activePlaceCategories;
  String                     get searchQuery           => _searchQuery;
  double                     get minScore              => _minScore;
  bool                       get onlyTrending          => _onlyTrending;
  bool                       get onlyHighSafety        => _onlyHighSafety;
  bool                       get onlyFamilyFriendly    => _onlyFamilyFriendly;

  bool get hasActiveFilters =>
      _activeFilter != NeighborhoodFilter.overall ||
      _activePlaceCategories.isNotEmpty ||
      _searchQuery.isNotEmpty ||
      _minScore > 0 ||
      _onlyTrending ||
      _onlyHighSafety ||
      _onlyFamilyFriendly;

  // ── Setters ──────────────────────────────────────────────────
  void setFilter(NeighborhoodFilter f) {
    _activeFilter = f;
    notifyListeners();
  }

  void togglePlaceCategory(PlaceCategoryType c) {
    if (_activePlaceCategories.contains(c)) {
      _activePlaceCategories.remove(c);
    } else {
      _activePlaceCategories.add(c);
    }
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  void setMinScore(double v) {
    _minScore = v;
    notifyListeners();
  }

  void toggleOnlyTrending() {
    _onlyTrending = !_onlyTrending;
    notifyListeners();
  }

  void toggleOnlyHighSafety() {
    _onlyHighSafety = !_onlyHighSafety;
    notifyListeners();
  }

  void toggleOnlyFamilyFriendly() {
    _onlyFamilyFriendly = !_onlyFamilyFriendly;
    notifyListeners();
  }

  void resetAll() {
    _activeFilter = NeighborhoodFilter.overall;
    _activePlaceCategories.clear();
    _searchQuery = '';
    _minScore = 0;
    _onlyTrending = false;
    _onlyHighSafety = false;
    _onlyFamilyFriendly = false;
    notifyListeners();
  }

  // ── Filtreleme Mantığı ────────────────────────────────────────
  /// NeighborhoodStats listesini aktif filtrelere göre sıralar ve filtreler
  List<NeighborhoodStats> apply(
    List<NeighborhoodStats> items,
    Map<String, NeighborhoodScoreResult> scoreResults,
  ) {
    var list = items.where((n) {
      final result = scoreResults[n.neighborhood];

      // Arama sorgusu
      if (_searchQuery.isNotEmpty) {
        final name = n.neighborhood.toLowerCase();
        if (!name.contains(_searchQuery)) return false;
      }

      // Min skor
      if (result != null && result.totalScore < _minScore) return false;

      // Yalnızca trend olanlar
      if (_onlyTrending && result != null) {
        if (result.trend != ScoreTrend.rising) return false;
      }

      // Yalnızca yüksek güvenlik
      if (_onlyHighSafety && result != null) {
        if (result.safetyPerception < 65) return false;
      }

      // Yalnızca aile dostu
      if (_onlyFamilyFriendly && result != null) {
        final familyScore = (result.safetyPerception + result.cleanlinessPerc) / 2;
        if (familyScore < 60) return false;
      }

      return true;
    }).toList();

    // Aktif filtreye göre sırala
    if (scoreResults.isNotEmpty) {
      list.sort((a, b) {
        final ra = scoreResults[a.neighborhood];
        final rb = scoreResults[b.neighborhood];
        if (ra == null || rb == null) return 0;
        final sa = _activeFilter.scoreFrom(ra);
        final sb = _activeFilter.scoreFrom(rb);
        return sb.compareTo(sa); // büyükten küçüğe
      });
    }

    return list;
  }

  /// Mekanları filtrele
  List<Place> applyToPlaces(List<Place> places) {
    return places.where((p) {
      if (_activePlaceCategories.isNotEmpty &&
          !_activePlaceCategories.contains(p.category)) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();
  }
}

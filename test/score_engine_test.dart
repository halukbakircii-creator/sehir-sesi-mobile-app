// test/score_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sehir_ses/services/score_engine.dart';

void main() {
  group('ScoreEngine.calculate', () {
    test('Skor 0-100 arasında olmalı', () {
      final result = ScoreEngine.calculate(
        touristInterest: 50,
        socialLife: 60,
        userSatisfaction: 70,
        accessibility: 40,
        cleanlinessPerc: 55,
        safetyPerception: 65,
        venueActivityDens: 45,
        trendDelta: 0,
      );
      expect(result.totalScore, greaterThanOrEqualTo(0));
      expect(result.totalScore, lessThanOrEqualTo(100));
    });

    test('Tüm değerler maksimumda 100 dönmeli', () {
      final result = ScoreEngine.calculate(
        touristInterest: 100,
        socialLife: 100,
        userSatisfaction: 100,
        accessibility: 100,
        cleanlinessPerc: 100,
        safetyPerception: 100,
        venueActivityDens: 100,
        trendDelta: 5,
      );
      expect(result.totalScore, 100);
    });

    test('Tüm değerler minimumda 0 dönmeli', () {
      final result = ScoreEngine.calculate(
        touristInterest: 0,
        socialLife: 0,
        userSatisfaction: 0,
        accessibility: 0,
        cleanlinessPerc: 0,
        safetyPerception: 0,
        venueActivityDens: 0,
        trendDelta: -5,
      );
      expect(result.totalScore, 0);
    });

    test('Trend bonus pozitif skoru artırmalı', () {
      final base = ScoreEngine.calculate(
        touristInterest: 50, socialLife: 50, userSatisfaction: 50,
        accessibility: 50, cleanlinessPerc: 50, safetyPerception: 50,
        venueActivityDens: 50, trendDelta: 0,
      );
      final withBonus = ScoreEngine.calculate(
        touristInterest: 50, socialLife: 50, userSatisfaction: 50,
        accessibility: 50, cleanlinessPerc: 50, safetyPerception: 50,
        venueActivityDens: 50, trendDelta: 5,
      );
      expect(withBonus.totalScore, greaterThan(base.totalScore));
    });

    test('Label eşikleri doğru çalışmalı', () {
      final harika = ScoreEngine.calculate(
        touristInterest: 90, socialLife: 90, userSatisfaction: 90,
        accessibility: 90, cleanlinessPerc: 90, safetyPerception: 90,
        venueActivityDens: 90, trendDelta: 0,
      );
      final kritik = ScoreEngine.calculate(
        touristInterest: 10, socialLife: 10, userSatisfaction: 10,
        accessibility: 10, cleanlinessPerc: 10, safetyPerception: 10,
        venueActivityDens: 10, trendDelta: 0,
      );
      expect(harika.label, 'Harika');
      expect(kritik.label, 'Kritik');
    });

    test('ScoreColor enum doğru renk eşliyor', () {
      expect(ScoreColor.darkGreen.hex, '#1E8449');
      expect(ScoreColor.red.hex, '#E74C3C');
    });
  });
}

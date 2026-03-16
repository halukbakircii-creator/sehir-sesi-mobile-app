// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sehir_ses/services/filter_service.dart';

void main() {
  testWidgets('FilterService başlatılabilmeli', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FilterService(),
        child: const MaterialApp(
          home: Scaffold(body: Text('Test')),
        ),
      ),
    );
    expect(find.text('Test'), findsOneWidget);
  });
}

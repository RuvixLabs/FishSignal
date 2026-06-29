import 'package:fishsignal/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launches onboarding and reaches Today screen', (tester) async {
    await tester.pumpWidget(const FishSignalApp());

    expect(find.text('FishSignal'), findsOneWidget);
    expect(find.textContaining('best two hours'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text(i == 4 ? 'Show my window' : 'Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.text('mock forecast'), findsOneWidget);
    expect(find.text('Open window'), findsOneWidget);
    expect(find.byIcon(Icons.speed_outlined), findsWidgets);
  });
}

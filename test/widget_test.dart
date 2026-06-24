import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osce_simulator/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const OsceSimulatorApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

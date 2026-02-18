import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/main.dart';
import 'package:provider/provider.dart';
import 'package:inventory_manager/providers/providers.dart';

void main() {
  testWidgets('App should build and show navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());
    
    // Wait for providers to initialize
    await tester.pump();
    
    // Verify that the app title is present
    expect(find.text('Инвентарь'), findsOneWidget);
    
    // Verify that navigation items are present
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Оборудование'), findsOneWidget);
    expect(find.text('Расходники'), findsOneWidget);
  });

  testWidgets('MultiProvider should provide all providers', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    
    final BuildContext context = tester.element(find.byType(MainNavigationScreen));
    
    // Verify all providers are available
    expect(Provider.of<EquipmentProvider>(context, listen: false), isNotNull);
    expect(Provider.of<EmployeeProvider>(context, listen: false), isNotNull);
    expect(Provider.of<ConsumableProvider>(context, listen: false), isNotNull);
    expect(Provider.of<MovementProvider>(context, listen: false), isNotNull);
  });
}

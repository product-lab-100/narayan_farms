import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navigation Architecture Constraints', () {
    test('ProductListScreen should NOT import system_core or repositories', () {
      final file = File('lib/features/product/view/product_list_screen.dart');
      final content = file.readAsStringSync();

      expect(content, isNot(contains('narayan_system_core')));
      expect(content, isNot(contains('repository')));
      // Allows facade via 'customer_aggregate_facade.dart' but not internal structure
      // Wait, facade is in 'application' layer. This is fine.
    });

    test('PlaceOrderScreen should NOT import orchestrators', () {
      final file = File('lib/features/order/view/place_order_screen.dart');
      final content = file.readAsStringSync();

      expect(content, isNot(contains('orchestrator')));
      // Should also not import UseCases directly
      expect(content, isNot(contains('use_case')));
    });

    test(
      'OrderStatusScreen should only depend on Bloc and Facade (if needed for provider)',
      () {
        final file = File('lib/features/order/view/order_status_screen.dart');
        final content = file.readAsStringSync();

        expect(content, isNot(contains('narayan_system_core')));
        expect(content, isNot(contains('repository')));
      },
    );
  });
}

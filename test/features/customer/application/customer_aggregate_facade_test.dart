import 'package:flutter_test/flutter_test.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';
import 'package:narayan_farms/features/customer/application/system_orchestrator.dart';
import 'package:narayan_farms/features/customer/model/domain/contact_info.dart';
import 'package:narayan_farms/features/customer/model/domain/customer.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_id.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_status.dart';

// Mock SystemOrchestrator using a simple Fake for test purity
class FakeSystemOrchestrator implements SystemOrchestrator {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> placedOrders = [];

  FakeSystemOrchestrator({this.products = const []});

  @override
  Future<List<Map<String, dynamic>>> getAvailableProducts() async {
    return products;
  }

  @override
  Future<String> placeOrder(
    CustomerId customerId,
    Map<String, int> items,
  ) async {
    placedOrders.add({'customerId': customerId.value, 'items': items});
    return 'fake-order-id';
  }

  @override
  Stream<String> trackOrderUpdates(CustomerId customerId) {
    return Stream.value('Order Placed');
  }
}

void main() {
  group('CustomerAggregateFacade', () {
    late Customer activeCustomer;
    late Customer blockedCustomer;
    late FakeSystemOrchestrator orchestrator;

    setUp(() {
      orchestrator = FakeSystemOrchestrator(
        products: [
          {'name': 'Milk'},
        ],
      );

      activeCustomer = Customer(
        id: CustomerId('123'),
        contactInfo: ContactInfo(phoneNumber: '9876543210'),
        status: CustomerStatus.active,
      );

      blockedCustomer = Customer(
        id: CustomerId('999'),
        contactInfo: ContactInfo(phoneNumber: '9999999999'),
        status: CustomerStatus.blocked,
      );
    });

    test('viewProfile should return safe projection of data', () {
      final facade = CustomerAggregateFacade(
        customer: activeCustomer,
        orchestrator: orchestrator,
      );

      final profile = facade.viewProfile();

      expect(profile['customerId'], '123');
      expect(profile['status'], 'active');
      // Ensure we didn't return the raw object
      // ignore: unnecessary_type_check
      expect(profile is Map, true);
    });

    test('viewAvailableProducts should delegate to orchestrator', () async {
      final facade = CustomerAggregateFacade(
        customer: activeCustomer,
        orchestrator: orchestrator,
      );

      final products = await facade.viewAvailableProducts();
      expect(products.length, 1);
      expect(products.first['name'], 'Milk');
    });

    test('placeOrder should delegate valid order to orchestrator', () async {
      final facade = CustomerAggregateFacade(
        customer: activeCustomer,
        orchestrator: orchestrator,
      );

      await facade.placeOrder({'milk': 2});

      expect(orchestrator.placedOrders.length, 1);
      expect(orchestrator.placedOrders.first['items'], {'milk': 2});
    });

    test('placeOrder should throw if customer is blocked', () async {
      final facade = CustomerAggregateFacade(
        customer: blockedCustomer,
        orchestrator: orchestrator,
      );

      expect(() => facade.placeOrder({'milk': 1}), throwsA(isA<StateError>()));
    });

    test('placeOrder should throw on empty order', () async {
      final facade = CustomerAggregateFacade(
        customer: activeCustomer,
        orchestrator: orchestrator,
      );

      expect(() => facade.placeOrder({}), throwsArgumentError);
    });

    test('placeOrder should throw on invalid quantities', () async {
      final facade = CustomerAggregateFacade(
        customer: activeCustomer,
        orchestrator: orchestrator,
      );

      expect(() => facade.placeOrder({'milk': -1}), throwsArgumentError);
    });
  });
}

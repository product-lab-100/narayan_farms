import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';
import 'package:narayan_farms/features/customer/application/system_orchestrator.dart';
import 'package:narayan_farms/features/customer/infrastructure/real_system_orchestrator.dart';
import 'package:narayan_farms/features/customer/model/domain/contact_info.dart';
import 'package:narayan_farms/features/customer/model/domain/customer.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_id.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_status.dart';
import 'package:narayan_farms/features/product/view_model/product_bloc.dart';
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:supply_inventory/supply_inventory.dart' as supply;

// -----------------------------------------------------------------------------
// FAKES FOR BLOC TESTING
// -----------------------------------------------------------------------------

class FakeClock implements ClockPort {
  DateTime _now = DateTime(2023, 1, 1);
  @override
  DateTime now() => _now;
}

class FakeEventBus implements EventBusPort {
  @override
  void emit(event) {}
}

class MockSystemOrchestrator extends Mock implements SystemOrchestrator {}

class MockPlaceOrderUseCase extends Mock implements PlaceOrderFromAppUseCase {}

// -----------------------------------------------------------------------------
// TESTS
// -----------------------------------------------------------------------------

void main() {
  group('ProductBloc Contract Tests', () {
    late FakeClock clock;
    late FakeEventBus eventBus;
    late supply.Inventory inventory;
    late supply.InventoryManagementService inventoryService;
    late SupplyFlowOrchestrator supplyOrchestrator;
    late RealSystemOrchestrator realSystemOrchestrator;
    late CustomerAggregateFacade facade;
    late Customer customer;

    setUp(() {
      clock = FakeClock();
      eventBus = FakeEventBus();

      // Use supply's own clock for its domain
      final supplyClock = supply.SystemClock();

      // 1. REAL DOMAIN: Inventory seeded with products
      // We rely on the REAL domain logic to hold this data.
      inventory = supply.Inventory(id: 'test-inv', clock: supplyClock);
      inventory.addProduct(
        productId: supply.ProductId('MILK-1L'),
        initialQuantity: supply.Quantity(10),
        unit: supply.Unit.liters,
        reorderPoint: supply.Quantity(2),
        productType: supply.ProductType.consumable,
      );

      inventoryService = supply.InventoryManagementService(
        inventory: inventory,
        restockPolicy: const supply.RestockPolicy(),
        clock: supplyClock,
      );

      supplyOrchestrator = SupplyFlowOrchestrator(
        inventoryService: inventoryService,
        clock: clock, // System Core ClockPort
        eventBus: eventBus,
      );

      // 2. REAL INFRASTRUCTURE
      realSystemOrchestrator = RealSystemOrchestrator(
        supplyOrchestrator: supplyOrchestrator,
        placeOrderUseCase: MockPlaceOrderUseCase(),
      );

      // 3. REAL FACADE
      customer = Customer(
        id: CustomerId('test-user'),
        contactInfo: ContactInfo(phoneNumber: '1234567890'),
        status: CustomerStatus.active,
      );

      facade = CustomerAggregateFacade(
        customer: customer,
        orchestrator: realSystemOrchestrator,
      );
    });

    blocTest<ProductBloc, ProductState>(
      'emits [Loading, Loaded] when products are fetched successfully thru REAL system',
      build: () => ProductBloc(customerFacade: facade),
      act: (bloc) => bloc.add(const LoadProducts()),
      expect: () => [
        const ProductLoading(),
        isA<ProductLoaded>()
            .having(
              (state) => state.products.first['name'],
              'product name',
              'MILK-1L',
            )
            .having(
              (state) => state.products.first['quantity'],
              'quantity',
              10,
            ),
      ],
    );
  });

  group('ProductBloc Failure Path', () {
    late MockSystemOrchestrator mockOrchestrator;
    late CustomerAggregateFacade facade;
    late Customer customer;

    setUp(() {
      mockOrchestrator = MockSystemOrchestrator();
      customer = Customer(
        id: CustomerId('test-user'),
        contactInfo: ContactInfo(phoneNumber: '1234567890'),
        status: CustomerStatus.active,
      );

      // We inject a mock orchestrator to simulate system failure
      facade = CustomerAggregateFacade(
        customer: customer,
        orchestrator: mockOrchestrator,
      );
    });

    blocTest<ProductBloc, ProductState>(
      'emits [Loading, Error] when facade throws',
      build: () => ProductBloc(customerFacade: facade),
      act: (bloc) {
        when(
          () => mockOrchestrator.getAvailableProducts(),
        ).thenThrow(Exception('System Down'));
        bloc.add(const LoadProducts());
      },
      expect: () => [
        const ProductLoading(),
        isA<ProductError>().having(
          (state) => state.message,
          'message',
          contains('System Down'),
        ),
      ],
    );
  });

  group('Architectural Assertions', () {
    test(
      'ProductListScreen does NOT import repositories, firebase, or system core',
      () {
        final file = File('lib/features/product/view/product_list_screen.dart');
        final content = file.readAsStringSync();

        expect(content, isNot(contains('repository')));
        expect(content, isNot(contains('firebase')));
        expect(content, isNot(contains('narayan_system_core')));
        // Should rely on Bloc only
        expect(content, contains('product_bloc.dart'));
      },
    );

    test('ProductBloc does NOT import flutter widgets or BuildContext', () {
      final file = File('lib/features/product/view_model/product_bloc.dart');
      final content = file.readAsStringSync();

      // "package:flutter/material.dart" contains widgets.
      // Equatable is allowed.
      // Flutter Bloc is allowed.
      // But the Bloc CLASS itself generally shouldn't depend on UI context directly if pure.
      // Importing 'package:flutter_bloc/flutter_bloc.dart' is typical for events/states/bloc base.
      // Importing 'package:flutter/material.dart' usually implies direct UI coupling.

      expect(content, isNot(contains('package:flutter/material.dart')));
      expect(content, isNot(contains('BuildContext')));
    });
  });
}

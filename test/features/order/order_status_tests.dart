import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';

import 'package:narayan_farms/features/order/view/order_status_screen.dart';
import 'package:narayan_farms/features/order/view_model/order_status_bloc.dart';

// -----------------------------------------------------------------------------
// FAKES / MOCKS
// -----------------------------------------------------------------------------

class MockCustomerFacade extends Mock implements CustomerAggregateFacade {}

class MockOrderStatusBloc extends MockBloc<OrderStatusEvent, OrderStatusState>
    implements OrderStatusBloc {}

void main() {
  group('OrderStatusBloc Tests', () {
    late MockCustomerFacade facade;

    setUp(() {
      facade = MockCustomerFacade();
    });

    blocTest<OrderStatusBloc, OrderStatusState>(
      'emits Created -> Assigned -> Delivered when system stream updates',
      build: () => OrderStatusBloc(customerFacade: facade),
      act: (bloc) {
        when(() => facade.trackOrders()).thenAnswer(
          (_) => Stream.fromIterable(['Created', 'Assigned', 'Delivered']),
        );
        bloc.add(const OrderStatusStarted('ord-1'));
      },
      expect: () => [
        const OrderStatusLoading(),
        const OrderStatusCreated(),
        const OrderStatusAssigned(),
        const OrderStatusDelivered(),
      ],
    );

    blocTest<OrderStatusBloc, OrderStatusState>(
      'emits Failed when system emits failure',
      build: () => OrderStatusBloc(customerFacade: facade),
      act: (bloc) {
        when(
          () => facade.trackOrders(),
        ).thenAnswer((_) => Stream.error('Network Error'));
        bloc.add(const OrderStatusStarted('ord-1'));
      },
      expect: () => [
        const OrderStatusLoading(),
        const OrderStatusFailed('Network Error'),
      ],
    );
  });

  group('OrderStatusScreen Widget Tests', () {
    late MockOrderStatusBloc mockBloc;

    setUp(() {
      mockBloc = MockOrderStatusBloc();
    });

    testWidgets('renders correct UI for each status', (tester) async {
      when(() => mockBloc.state).thenReturn(const OrderStatusCreated());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<OrderStatusBloc>.value(
            value: mockBloc,
            child: const OrderStatusScreen(orderId: '123'),
          ),
        ),
      );

      expect(find.text('State: Created'), findsOneWidget);

      // Verify initialization event
      verify(() => mockBloc.add(const OrderStatusStarted('123'))).called(1);
    });
  });

  group('Architectural Assertions', () {
    test(
      'OrderStatusScreen does NOT import repositories, firebase, or system core',
      () {
        final file = File('lib/features/order/view/order_status_screen.dart');
        final content = file.readAsStringSync();
        expect(content, isNot(contains('repository')));
        expect(content, isNot(contains('firebase')));
        expect(content, isNot(contains('narayan_system_core')));
      },
    );

    test(
      'OrderStatusBloc does NOT import flutter/material or BuildContext',
      () {
        final file = File(
          'lib/features/order/view_model/order_status_bloc.dart',
        );
        final content = file.readAsStringSync();
        expect(content, isNot(contains('package:flutter/material.dart')));
        expect(content, isNot(contains('BuildContext')));
      },
    );
  });
}

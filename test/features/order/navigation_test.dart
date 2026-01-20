import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';
import 'package:narayan_farms/features/order/view/order_status_screen.dart';
import 'package:narayan_farms/features/order/view/place_order_screen.dart';
import 'package:narayan_farms/features/order/view_model/place_order_bloc.dart';
import 'package:narayan_farms/features/order/view_model/order_status_bloc.dart'; // Needed for type check

class MockPlaceOrderBloc extends MockBloc<PlaceOrderEvent, PlaceOrderState>
    implements PlaceOrderBloc {}

class MockOrderStatusBloc extends MockBloc<OrderStatusEvent, OrderStatusState>
    implements OrderStatusBloc {}

class MockCustomerFacade extends Mock implements CustomerAggregateFacade {}

void main() {
  // Fix for "OrderStatusBloc isn't a type" generic error during route construction?
  // We need to ensure we provide dependencies so the route builder doesn't crash.

  testWidgets(
    'PlaceOrderScreen navigates to OrderStatusScreen on PlaceOrderSuccess',
    (tester) async {
      final mockPlaceOrderBloc = MockPlaceOrderBloc();
      final mockFacade = MockCustomerFacade();

      // Stub facade because OrderStatusScreen's BlocProvider needs it to create OrderStatusBloc
      // Wait, the builder creates a BlocProvider<OrderStatusBloc>(create: ...).
      // We need to ensure context.read<CustomerAggregateFacade> works.

      // We also need to stub OrderStatusBloc or let it be created?
      // If we let it be created, we need to stub Facade methods called in init.
      // OrderStatusBloc calls trackOrders on init event.
      when(
        () => mockFacade.trackOrders(),
      ).thenAnswer((_) => Stream.value('Created'));

      // Observer removed as we verify via find.byType

      final stateController = StreamController<PlaceOrderState>();

      when(
        () => mockPlaceOrderBloc.state,
      ).thenReturn(const PlaceOrderInitial());
      whenListen(mockPlaceOrderBloc, stateController.stream);

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CustomerAggregateFacade>.value(
              value: mockFacade,
            ),
          ],
          child: MaterialApp(
            home: BlocProvider<PlaceOrderBloc>.value(
              value: mockPlaceOrderBloc,
              child: const PlaceOrderScreen(productId: 'P1', productName: 'N'),
            ),
          ),
        ),
      );

      // Initial State
      expect(find.byType(PlaceOrderScreen), findsOneWidget);

      // Trigger Success
      stateController.add(const PlaceOrderSuccess('ord-555'));

      // Process stream event
      await tester.pump();
      // Process navigation
      await tester.pumpAndSettle();

      // Verify Navigation
      expect(find.byType(OrderStatusScreen), findsOneWidget);
      expect(find.text('Order #ord-555'), findsOneWidget);

      await stateController.close();
    },
  );
}

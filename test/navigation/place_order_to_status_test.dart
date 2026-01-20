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

class MockPlaceOrderBloc extends MockBloc<PlaceOrderEvent, PlaceOrderState>
    implements PlaceOrderBloc {}

class MockCustomerFacade extends Mock implements CustomerAggregateFacade {}

// Correction: PlaceOrderEvent is sealed. We cannot implement it.
// We should use a concrete implementation or just registered fallback of a concrete one.
class FakePlaceOrderPressed extends PlaceOrderPressed {
  FakePlaceOrderPressed() : super(productId: '', quantity: 0);
}

void main() {
  late MockPlaceOrderBloc mockPlaceOrderBloc;
  late MockCustomerFacade mockFacade;

  setUpAll(() {
    registerFallbackValue(FakePlaceOrderPressed());
  });

  setUp(() {
    mockPlaceOrderBloc = MockPlaceOrderBloc();
    mockFacade = MockCustomerFacade();
    // Needed for OrderStatusScreen init
    when(
      () => mockFacade.trackOrders(),
    ).thenAnswer((_) => Stream.value('Created'));
  });

  Future<void> pumpPlaceOrderScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CustomerAggregateFacade>.value(value: mockFacade),
        ],
        child: MaterialApp(
          home: BlocProvider<PlaceOrderBloc>.value(
            value: mockPlaceOrderBloc,
            child: const PlaceOrderScreen(productId: 'P1', productName: 'Milk'),
          ),
        ),
      ),
    );
  }

  testWidgets('PlaceOrderSuccess triggers navigation to OrderStatusScreen', (
    tester,
  ) async {
    final stateController = StreamController<PlaceOrderState>();
    when(() => mockPlaceOrderBloc.state).thenReturn(const PlaceOrderInitial());
    whenListen(mockPlaceOrderBloc, stateController.stream);

    await pumpPlaceOrderScreen(tester);

    // Act: Emit Success
    stateController.add(const PlaceOrderSuccess('ORD-123'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Assert: Navigation happened
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(find.text('Order #ORD-123'), findsOneWidget);

    await stateController.close();
  });

  testWidgets('PlaceOrderError does NOT trigger navigation', (tester) async {
    final stateController = StreamController<PlaceOrderState>();
    when(() => mockPlaceOrderBloc.state).thenReturn(const PlaceOrderInitial());
    whenListen(mockPlaceOrderBloc, stateController.stream);

    await pumpPlaceOrderScreen(tester);

    // Act: Emit Error
    stateController.add(const PlaceOrderError('Failed'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Assert: Still on PlaceOrderScreen
    expect(find.byType(OrderStatusScreen), findsNothing);
    expect(find.byType(PlaceOrderScreen), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget); // Checks UI Error Text

    await stateController.close();
  });

  testWidgets('Button press dispatch event only, does NOT navigate directly', (
    tester,
  ) async {
    when(() => mockPlaceOrderBloc.state).thenReturn(const PlaceOrderInitial());

    await pumpPlaceOrderScreen(tester);

    // Enter Qty
    await tester.enterText(find.byType(TextField), '5');

    // Tap Button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Place Order'));

    // Assert Event Dispatched
    verify(
      () => mockPlaceOrderBloc.add(any(that: isA<PlaceOrderEvent>())),
    ).called(1);

    // Assert NO Navigation (since state hasn't changed to Success)
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(OrderStatusScreen), findsNothing);
  });
}

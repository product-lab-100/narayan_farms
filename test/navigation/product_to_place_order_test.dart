import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';
import 'package:narayan_farms/features/order/view/place_order_screen.dart';
import 'package:narayan_farms/features/order/view_model/place_order_bloc.dart';
import 'package:narayan_farms/features/product/view/product_list_screen.dart';
import 'package:narayan_farms/features/product/view_model/product_bloc.dart';

class MockProductBloc extends MockBloc<ProductEvent, ProductState>
    implements ProductBloc {}

class MockPlaceOrderBloc extends MockBloc<PlaceOrderEvent, PlaceOrderState>
    implements PlaceOrderBloc {}

class MockCustomerFacade extends Mock implements CustomerAggregateFacade {}

void main() {
  testWidgets(
    'Tapping product tile pushes PlaceOrderScreen with correct args',
    (tester) async {
      final mockProductBloc = MockProductBloc();
      final mockPlaceOrderBloc = MockPlaceOrderBloc();
      final mockFacade = MockCustomerFacade();

      when(() => mockProductBloc.state).thenReturn(
        const ProductLoaded([
          {'name': 'Milk', 'quantity': 10, 'unit': 'Liters'},
        ]),
      );

      // PlaceOrderScreen requires PlaceOrderBloc Provider
      // The navigation builder creates a provider using context.read.
      // In test, we must provide it above ProductList.

      when(
        () => mockPlaceOrderBloc.state,
      ).thenReturn(const PlaceOrderInitial());

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CustomerAggregateFacade>.value(
              value: mockFacade,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ProductBloc>.value(value: mockProductBloc),
              BlocProvider<PlaceOrderBloc>.value(value: mockPlaceOrderBloc),
            ],
            child: const MaterialApp(home: ProductListScreen()),
          ),
        ),
      );

      // Verify list renders
      expect(find.text('Milk'), findsOneWidget);

      // Tap Item
      await tester.tap(find.text('Milk'));
      await tester.pumpAndSettle();

      // Verify Navigation to PlaceOrderScreen
      final placeOrderScreenFinder = find.byType(PlaceOrderScreen);
      expect(placeOrderScreenFinder, findsOneWidget);

      // Verify Args
      final widget = tester.widget<PlaceOrderScreen>(placeOrderScreenFinder);
      expect(widget.productName, 'Milk');
      // Implementation uses name as ID currently (from code view)
      expect(widget.productId, 'Milk');
    },
  );
}

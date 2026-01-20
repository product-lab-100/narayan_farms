import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';

// -----------------------------------------------------------------------------
// EVENTS
// -----------------------------------------------------------------------------

sealed class PlaceOrderEvent extends Equatable {
  const PlaceOrderEvent();
}

class PlaceOrderPressed extends PlaceOrderEvent {
  final String productId;
  final int quantity;

  const PlaceOrderPressed({required this.productId, required this.quantity});

  @override
  List<Object> get props => [productId, quantity];
}

// -----------------------------------------------------------------------------
// STATES
// -----------------------------------------------------------------------------

sealed class PlaceOrderState extends Equatable {
  const PlaceOrderState();

  @override
  List<Object> get props => [];
}

class PlaceOrderInitial extends PlaceOrderState {
  const PlaceOrderInitial();
}

class PlaceOrderSubmitting extends PlaceOrderState {
  const PlaceOrderSubmitting();
}

class PlaceOrderSuccess extends PlaceOrderState {
  final String
  message; // Or orderId if we had it returned easily from facade void

  const PlaceOrderSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class PlaceOrderError extends PlaceOrderState {
  final String message;

  const PlaceOrderError(this.message);

  @override
  List<Object> get props => [message];
}

// -----------------------------------------------------------------------------
// BLOC
// -----------------------------------------------------------------------------

class PlaceOrderBloc extends Bloc<PlaceOrderEvent, PlaceOrderState> {
  final CustomerAggregateFacade _customerFacade;

  PlaceOrderBloc({required CustomerAggregateFacade customerFacade})
    : _customerFacade = customerFacade,
      super(const PlaceOrderInitial()) {
    on<PlaceOrderPressed>(_onPlaceOrderPressed);
  }

  Future<void> _onPlaceOrderPressed(
    PlaceOrderPressed event,
    Emitter<PlaceOrderState> emit,
  ) async {
    emit(const PlaceOrderSubmitting());
    try {
      // Maps to Map<String, int> as expected by Facade
      final items = {event.productId: event.quantity};

      await _customerFacade.placeOrder(items);

      emit(const PlaceOrderSuccess('Order Placed Successfully'));
    } catch (e) {
      emit(PlaceOrderError(e.toString()));
    }
  }
}

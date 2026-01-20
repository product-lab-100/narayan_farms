import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';

// -----------------------------------------------------------------------------
// EVENTS
// -----------------------------------------------------------------------------

sealed class OrderStatusEvent extends Equatable {
  const OrderStatusEvent();
}

class OrderStatusStarted extends OrderStatusEvent {
  final String orderId;

  const OrderStatusStarted(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class _OrderStatusUpdated extends OrderStatusEvent {
  final String status;

  const _OrderStatusUpdated(this.status);

  @override
  List<Object> get props => [status];
}

// -----------------------------------------------------------------------------
// STATES
// -----------------------------------------------------------------------------

sealed class OrderStatusState extends Equatable {
  const OrderStatusState();

  @override
  List<Object> get props => [];
}

class OrderStatusInitial extends OrderStatusState {
  const OrderStatusInitial();
}

class OrderStatusLoading extends OrderStatusState {
  const OrderStatusLoading();
}

class OrderStatusCreated extends OrderStatusState {
  const OrderStatusCreated();
}

class OrderStatusAssigned extends OrderStatusState {
  const OrderStatusAssigned();
}

class OrderStatusDelivered extends OrderStatusState {
  const OrderStatusDelivered();
}

class OrderStatusFailed extends OrderStatusState {
  final String message;
  const OrderStatusFailed(this.message);
  @override
  List<Object> get props => [message];
}

// -----------------------------------------------------------------------------
// BLOC
// -----------------------------------------------------------------------------

class OrderStatusBloc extends Bloc<OrderStatusEvent, OrderStatusState> {
  final CustomerAggregateFacade _customerFacade;
  StreamSubscription<String>? _subscription;

  OrderStatusBloc({required CustomerAggregateFacade customerFacade})
    : _customerFacade = customerFacade,
      super(const OrderStatusInitial()) {
    on<OrderStatusStarted>(_onStarted);
    on<_OrderStatusUpdated>(_onUpdated);
  }

  Future<void> _onStarted(
    OrderStatusStarted event,
    Emitter<OrderStatusState> emit,
  ) async {
    emit(const OrderStatusLoading());

    await _subscription?.cancel();
    _subscription = _customerFacade
        .trackOrders() // Facade tracks all, logic might be to filter by ID here or Facade
        // For this "Simple" app, we assume the stream corresponds to relevant updates
        .listen(
          (status) => add(_OrderStatusUpdated(status)),
          onError: (Object error) => add(_OrderStatusUpdated('FAILED: $error')),
        );
  }

  void _onUpdated(_OrderStatusUpdated event, Emitter<OrderStatusState> emit) {
    switch (event.status) {
      case 'Created':
        emit(const OrderStatusCreated());
        break;
      case 'Assigned':
        emit(const OrderStatusAssigned());
        break;
      case 'Delivered':
        emit(const OrderStatusDelivered());
        break;
      default:
        // Handle failure or unknown
        if (event.status.startsWith('FAILED:')) {
          emit(OrderStatusFailed(event.status.replaceFirst('FAILED: ', '')));
        } else {
          // Treating unknown as Created or ignore?
          // Let's assume Created if unknown for safety or Failed?
          // Strict: Failed if unknown? No, maybe just ignore or map to Created.
          // Let's map to Failed for strictness check.
          emit(OrderStatusFailed('Unknown Status: ${event.status}'));
        }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

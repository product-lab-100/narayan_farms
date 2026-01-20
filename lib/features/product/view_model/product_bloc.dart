import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';

// -----------------------------------------------------------------------------
// EVENTS
// -----------------------------------------------------------------------------

sealed class ProductEvent extends Equatable {
  const ProductEvent();
}

class LoadProducts extends ProductEvent {
  const LoadProducts();

  @override
  List<Object> get props => [];
}

// -----------------------------------------------------------------------------
// STATES
// -----------------------------------------------------------------------------

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<Map<String, dynamic>> products;

  const ProductLoaded(this.products);

  @override
  List<Object> get props => [products];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}

// -----------------------------------------------------------------------------
// BLOC
// -----------------------------------------------------------------------------

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final CustomerAggregateFacade _customerFacade;

  ProductBloc({required CustomerAggregateFacade customerFacade})
    : _customerFacade = customerFacade,
      super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final products = await _customerFacade.viewAvailableProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}

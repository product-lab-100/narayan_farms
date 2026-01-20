import 'package:narayan_farms/features/customer/application/system_orchestrator.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_id.dart';
import 'package:narayan_system_core/narayan_system_core.dart';

/// **RealSystemOrchestrator**
///
/// Concrete implementation of [SystemOrchestrator] that connects to the
/// real system brain [SupplyFlowOrchestrator].
class RealSystemOrchestrator implements SystemOrchestrator {
  final SupplyFlowOrchestrator _supplyOrchestrator;
  final PlaceOrderFromAppUseCase _placeOrderUseCase;

  RealSystemOrchestrator({
    required SupplyFlowOrchestrator supplyOrchestrator,
    required PlaceOrderFromAppUseCase placeOrderUseCase,
  }) : _supplyOrchestrator = supplyOrchestrator,
       _placeOrderUseCase = placeOrderUseCase;

  @override
  Future<List<Map<String, dynamic>>> getAvailableProducts() async {
    // Accessing inventory service from orchestrator (assuming public)
    // and then inventory items.
    final allItems = _supplyOrchestrator.inventoryService.inventory.items;

    return allItems.values.map((stockItem) {
      return {
        'id': stockItem.productId.value,
        'name': stockItem.productId.value, // Simple mapping for now
        'quantity': stockItem.quantity.value,
        'unit': stockItem.unit.value,
      };
    }).toList();
  }

  @override
  Future<void> placeOrder(CustomerId customerId, Map<String, int> items) async {
    if (items.isEmpty) return;

    // The simplified UseCase currently supports one item per request structure logic,
    // or we iterate. The prompt implies "Place Order" acts as a transaction.
    // However, PlaceOrderFromAppInput takes ONE productId.
    // We will loop or pick the first for this specific step as the UI
    // "PlaceOrderScreen" likely focuses on ordering A product (singular).
    // Let's assume the UI sends one item for now as per the "product list -> order" flow.

    for (final entry in items.entries) {
      final input = PlaceOrderFromAppInput(
        customerId: customerId.value,
        productId: entry.key,
        quantity: entry.value,
      );

      final result = await _placeOrderUseCase.execute(input);

      if (!result.success) {
        throw Exception(result.errorMessage ?? 'Order Failed');
      }
    }
  }

  @override
  Stream<String> trackOrderUpdates(CustomerId customerId) {
    // TODO: Implement for future task
    throw UnimplementedError();
  }
}

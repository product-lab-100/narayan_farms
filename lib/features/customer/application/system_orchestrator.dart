import 'package:narayan_farms/features/customer/model/domain/customer_id.dart';

/// **SystemOrchestrator**
///
/// Abstract interface representing the external system capabilities
/// available to the Customer domain.
///
/// **Role**:
/// - Decouples the Customer facade from concrete system services (Orders, Inventory).
/// - Defines exactly what the Customer is allowed to ask the system to do.
///
/// **Invariants**:
/// - Must return Futures/Streams.
/// - Implementations are responsible for crossing domain boundaries.
abstract class SystemOrchestrator {
  /// Fetches the list of products currently available for ordering.
  /// Returns a simple list of product details (represented as generic Map or simple DTO for now,
  /// since Product entity is not in this scope, but Facade rule says NO DTOs...
  /// actually rule says NO DTO coding, but we need return types.
  /// The prompt says "Future<List<Product>>" in plan, but Product isn't in scope.
  /// I will use `List<String>` or a simple placeholder class if needed, or strictly typeless `List<Object>`.
  /// Let's use `List<String>` (Product Names) or similar simple type for this isolated task to avoid importing unknown files.
  /// Or better, just `Future<void>` for the "view" actions if we can't return real objects,
  /// BUT the plan said "viewAvailableProducts".
  /// I will define a minimal `ProductSummary` class inside this file or assume it exists?
  /// No, "Design ONLY these entities" applied to the previous turn.
  /// This turn says "Orchestrator interface it depends on".
  /// I will use a generic `Map<String, dynamic>` to represent data to keep it pure and standalone
  /// without inventing fake entities that might conflict later.
  Future<List<Map<String, dynamic>>> getAvailableProducts();

  /// Places an order for the authenticated customer.
  /// [items] is a Map of ProductId -> Quantity.
  Future<void> placeOrder(CustomerId customerId, Map<String, int> items);

  /// Returns a stream of status updates for the customer's active orders.
  Stream<String> trackOrderUpdates(CustomerId customerId);
}

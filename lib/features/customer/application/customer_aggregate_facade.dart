import 'package:narayan_farms/features/customer/model/domain/customer.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_id.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_status.dart';
import 'system_orchestrator.dart';

/// **CustomerAggregateFacade**
///
/// A protective boundary around the Customer Core Domain.
///
/// **Role**:
/// - Exposes ONLY intent-based actions available to the Customer App UI.
/// - Hides the raw [Customer] entity to prevent direct mutation or misuse.
/// - Delegates complex system interactions (Orders, etc.) to [SystemOrchestrator].
///
/// **Invariants**:
/// - Takes a valid [CustomerId] and [SystemOrchestrator] on creation.
/// - NEVER exposes the raw [Customer] entity (if we had one internally, but we might just hold ID if we fetch fresh).
/// - Actually, facade usually wraps an instance or fetches it.
/// - Constraint: "Wraps an existing core Customer".
/// - So we will hold `_customer` but NOT expose it.
class CustomerAggregateFacade {
  final Customer _customer;
  final SystemOrchestrator _orchestrator;

  /// **Constructor**
  ///
  /// Requires a valid [Customer] domain entity and a [SystemOrchestrator].
  /// The UI should obtain this facade from a trusted factory/provider, not build it manually with raw entities ideally,
  /// but for this design, we rely on the constructor.
  CustomerAggregateFacade({
    required Customer customer,
    required SystemOrchestrator orchestrator,
  }) : _customer = customer,
       _orchestrator = orchestrator;

  // ---------------------------------------------------------------------------
  // READ-ONLY VIEWS (Safe Projections)
  // ---------------------------------------------------------------------------

  /// Returns the Customer's ID. Safe to expose as it's a value object.
  CustomerId get id => _customer.id;

  /// Returns the Customer's Status. Safe enum.
  CustomerStatus get status => _customer.status;

  /// Returns a safe, immutable map of profile details.
  /// WE DO NOT return [ContactInfo] directly if we want to be super strict about "leaking core entities",
  /// but Value Objects are usually safe to leak. The prompt says "No leaking core entities".
  /// To be safe and "boring", we return a plain Map or DTO-like structure.
  Map<String, String?> viewProfile() {
    return {
      'customerId': _customer.id.value,
      'phoneNumber': _customer.contactInfo.phoneNumber,
      'email': _customer.contactInfo.email,
      'status': _customer.status.name,
    };
  }

  // ---------------------------------------------------------------------------
  // INTENT-BASED ACTIONS (Delegated to Orchestrator)
  // ---------------------------------------------------------------------------

  /// **viewAvailableProducts**
  ///
  /// Delegates to the system to find what this customer can buy.
  Future<List<Map<String, dynamic>>> viewAvailableProducts() async {
    _ensureActive();
    return _orchestrator.getAvailableProducts();
  }

  /// **placeOrder**
  ///
  /// Validates intent and delegates to orchestrator.
  /// [items] is Map<ProductId, Quantity>.
  Future<void> placeOrder(Map<String, int> items) async {
    _ensureActive();

    if (items.isEmpty) {
      throw ArgumentError('Cannot place an empty order.');
    }

    // Facade validation: Are quantities valid?
    if (items.values.any((qty) => qty <= 0)) {
      throw ArgumentError('Order quantities must be positive.');
    }

    await _orchestrator.placeOrder(_customer.id, items);
  }

  /// **trackOrders**
  ///
  /// Returns a live stream of order updates for this customer.
  Stream<String> trackOrders() {
    // Even tracking might be restricted if blocked
    _ensureActive();
    return _orchestrator.trackOrderUpdates(_customer.id);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  /// **_ensureActive**
  ///
  /// Facade-level guard to prevent actions if customer is not active.
  /// This enforces functionality security at the edge.
  void _ensureActive() {
    if (_customer.status != CustomerStatus.active) {
      throw StateError(
        'Customer is ${_customer.status.name}. Actions are restricted.',
      );
    }
  }
}

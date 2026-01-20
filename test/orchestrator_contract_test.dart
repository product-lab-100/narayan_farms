// ignore: unused_import
import 'package:customer_relation/customer_relation.dart' as customer_pkg;
import 'package:delivery_workforce/delivery_workforce.dart' as delivery;
import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_levels/loyalty_levels.dart' as loyalty;
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:narayan_system_core/use_cases/order_placement_use_case.dart';
import 'package:ordering/ordering.dart' as ordering;

import 'package:supply_inventory/supply_inventory.dart' as supply;

// -----------------------------------------------------------------------------
// FAKE INFRASTRUCTURE / PORTS
// -----------------------------------------------------------------------------

class FakeClock implements ClockPort {
  DateTime _now = DateTime(2023, 1, 1, 10, 0);

  @override
  DateTime now() => _now;
}

class FakeDomainEventBus implements DomainEventBus {
  final List<DomainEvent> events = [];

  @override
  void publish(DomainEvent event) {
    events.add(event);
  }
}

class FakeEventBusPort implements EventBusPort {
  final List<dynamic> events = [];

  @override
  void emit(event) {
    events.add(event);
  }
}

// -----------------------------------------------------------------------------
// ORDERING DOMAIN FAKES
// -----------------------------------------------------------------------------

class FakeOrderRepository implements ordering.OrderRepository {
  final List<ordering.Order> _orders = [];

  List<ordering.Order> get savedOrders => _orders;

  @override
  ordering.Order findById(String orderId) {
    return _orders.firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => throw Exception('Order not found'),
    );
  }

  @override
  void save(ordering.Order order) {
    _orders.add(order);
  }

  @override
  void update(ordering.Order order) {
    final index = _orders.indexWhere((o) => o.orderId == order.orderId);
    if (index != -1) {
      _orders[index] = order;
    }
  }
}

class FakeInventoryPort implements ordering.InventoryPort {
  final Map<String, int> _availability = {};

  void setAvailability(String productId, int qty) {
    _availability[productId] = qty;
  }

  @override
  bool isAvailable({required String productId, required double quantity}) {
    // Simple mock logic
    return (_availability[productId] ?? 0) >= quantity;
  }

  @override
  void reserve({
    required String productId,
    required double quantity,
    required String orderId,
  }) {}

  @override
  void release({
    required String productId,
    required double quantity,
    required String orderId,
  }) {}
}

class FakePricingPort implements ordering.PricingPort {
  @override
  ordering.Money getPrice({
    required String productId,
    required DateTime at,
    ordering.Subscription? subscription,
  }) {
    return ordering.Money.inrRupees(50);
  }
}

class FakeLoyaltyPort implements ordering.LoyaltyPort {
  @override
  void addPoints({
    required String customerId,
    required String orderId,
    required ordering.Money orderAmount,
  }) {}

  @override
  void revertPoints({required String customerId, required String orderId}) {}

  @override
  double applyDiscount({
    required String customerId,
    required double orderAmount,
  }) {
    return 0.0;
  }

  @override
  bool isEligible({required String customerId}) {
    return true;
  }
}

// -----------------------------------------------------------------------------
// SYSTEM PORTS FAKES
// -----------------------------------------------------------------------------

class FakeAgentProvider implements AgentProviderPort {
  @override
  List<delivery.DeliveryAgent> getAvailableAgents() {
    return [
      delivery.DeliveryAgent(
        id: delivery.DeliveryAgentId('agent-1'),
        role: delivery.AgentRole.delivery, // Adjusted role
        status: delivery.AgentStatus.active,
      ),
    ];
  }
}

class FakeRouteProvider implements RouteProviderPort {
  @override
  delivery.Route getRouteForCustomer(String customerId) {
    return delivery.Route(
      id: delivery.RouteId('route-1'),
      startLocation: const delivery.GeoArea('A'),
      endLocation: const delivery.GeoArea('B'),
      distanceKm: 5.0,
    );
  }
}

class FakeLoyaltyAccountProvider implements LoyaltyAccountProviderPort {
  bool failForBlocked = false;

  @override
  loyalty.LoyaltyAccount getAccountForCustomer(String customerId) {
    if (failForBlocked && customerId == 'cust-blocked') {
      throw StateError('Customer is blocked');
    }
    return loyalty.LoyaltyAccount.create(
      accountId: customerId,
      createdAt: DateTime(2023),
    );
  }
}

// -----------------------------------------------------------------------------
// TESTS
// -----------------------------------------------------------------------------

void main() {
  group('Orchestrator Contract Tests', () {
    // Infrastructure
    late FakeClock clock;
    late FakeEventBusPort eventBus;
    late FakeDomainEventBus domainEventBus;

    // Domain Services & Entities
    late ordering.OrderService orderService;
    late supply.InventoryManagementService inventoryService;
    late delivery.AssignmentManagementService assignmentService;
    late loyalty.LoyaltyEvaluationService loyaltyService;

    // Ports/Repos
    late FakeOrderRepository orderRepo;
    late FakeInventoryPort inventoryPort;
    late FakePricingPort pricingPort;
    late FakeLoyaltyPort loyaltyPort;

    // System Helpers
    late FakeAgentProvider agentProvider;
    late FakeRouteProvider routeProvider;
    late FakeLoyaltyAccountProvider loyaltyAccountProvider;

    // Entry Point
    late PlaceOrderFromAppUseCase placeOrderUseCase;

    setUp(() {
      clock = FakeClock();
      eventBus = FakeEventBusPort();
      domainEventBus = FakeDomainEventBus();

      // 1. Setup Ordering
      orderRepo = FakeOrderRepository();
      inventoryPort = FakeInventoryPort();
      pricingPort = FakePricingPort();
      loyaltyPort = FakeLoyaltyPort();

      orderService = ordering.OrderService(
        orderRepository: orderRepo,
        inventoryPort: inventoryPort,
        pricingPort: pricingPort,
        loyaltyPort: loyaltyPort,
      );

      // 2. Setup Supply (Real Entity)
      final supplyClock = supply.SystemClock();
      final inventory = supply.Inventory(id: 'inv-1', clock: supplyClock);

      // Pre-fill inventory
      inventory.addProduct(
        productId: supply.ProductId('MILK-1L'),
        initialQuantity: supply.Quantity(100),
        unit: supply.Unit.liters,
        reorderPoint: supply.Quantity(10),
        productType: supply.ProductType.consumable, // Adjusted enum
      );

      inventoryService = supply.InventoryManagementService(
        inventory: inventory,
        restockPolicy: const supply.RestockPolicy(),
        clock: supplyClock,
      );

      // 3. Setup Delivery
      assignmentService = delivery.AssignmentManagementService(
        delivery.SystemClock(),
        delivery.AssignmentPolicy(),
      );

      // 4. Setup Loyalty
      loyaltyService = loyalty.LoyaltyEvaluationService(
        clock: loyalty.SystemClock(),
      );

      // 5. Orchestrator
      // Note: we pass OUR FakeClock/Events to orchestrator
      final orchestrator = OrderFlowOrchestrator(
        orderService: orderService,
        inventoryService: inventoryService,
        assignmentService: assignmentService,
        loyaltyService: loyaltyService,
        clock: clock,
        eventBus: eventBus,
        domainEventBus: domainEventBus,
      );

      // 6. Use Case Dependencies
      agentProvider = FakeAgentProvider();
      routeProvider = FakeRouteProvider();
      loyaltyAccountProvider = FakeLoyaltyAccountProvider();

      // 7. System Entry Point
      placeOrderUseCase = PlaceOrderFromAppUseCase(
        orderPlacementUseCase: OrderPlacementUseCase(
          orchestrator: orchestrator,
          clock: clock,
          eventBus: eventBus,
        ),
        clock: clock,
        agentProvider: agentProvider,
        routeProvider: routeProvider,
        loyaltyAccountProvider: loyaltyAccountProvider,
      );
    });

    test('OrderPlacementUseCase succeeds end-to-end', () async {
      // GIVEN
      const customerId = 'cust-1';
      const productId = 'MILK-1L';
      const quantity = 2;

      // Ensure InventoryPort (for Ordering Service check) says YES
      inventoryPort.setAvailability(productId, 100);

      // ACT
      final result = await placeOrderUseCase.execute(
        PlaceOrderFromAppInput(
          customerId: customerId,
          productId: productId,
          quantity: quantity,
        ),
      );

      // ASSERT
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.orderId, isNotEmpty);

      // 1. Order Persisted
      expect(orderRepo.savedOrders.length, 1);

      // 2. Events Emitted
      expect(eventBus.events.any((e) => e is OrderCompleted), isTrue);
    });

    test('OrderPlacementUseCase fails when inventory insufficient', () async {
      // GIVEN
      const customerId = 'cust-1';
      const productId = 'MILK-1L';

      // InventoryPort says NO
      inventoryPort.setAvailability(productId, 0);

      // ACT
      final result = await placeOrderUseCase.execute(
        PlaceOrderFromAppInput(
          customerId: customerId,
          productId: productId,
          quantity: 5,
        ),
      );

      // ASSERT
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('not available'));

      // No Order Saved
      expect(orderRepo.savedOrders, isEmpty);
    });

    test('Blocked customer cannot place order', () async {
      // GIVEN
      const customerId = 'cust-blocked';
      loyaltyAccountProvider.failForBlocked = true;

      // ACT
      final result = await placeOrderUseCase.execute(
        PlaceOrderFromAppInput(
          customerId: customerId,
          productId: 'MILK-1L',
          quantity: 1,
        ),
      );

      // ASSERT
      expect(result.success, isFalse);

      // No side effects
      expect(orderRepo.savedOrders, isEmpty);
    });
  });
}

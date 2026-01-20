import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/features/auth/view_model/bloc/auth_bloc.dart';
import 'package:narayan_farms/features/auth/model/repository/auth_repository.dart';

import 'package:narayan_farms/firebase_options.dart';

import 'package:narayan_farms/features/customer/application/customer_aggregate_facade.dart';
import 'package:narayan_farms/features/customer/infrastructure/real_system_orchestrator.dart';
import 'package:narayan_farms/features/customer/model/domain/contact_info.dart';
import 'package:narayan_farms/features/customer/model/domain/customer.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_id.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_status.dart';
import 'package:narayan_farms/features/product/view/product_list_screen.dart';
import 'package:narayan_farms/features/product/view_model/product_bloc.dart';
import 'package:narayan_farms/features/customer/infrastructure/main_providers.dart';
import 'package:narayan_farms/features/order/view_model/place_order_bloc.dart';
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:narayan_system_core/use_cases/order_placement_use_case.dart';
import 'package:supply_inventory/supply_inventory.dart' as supply;
import 'package:ordering/ordering.dart' as ordering;
import 'package:delivery_workforce/delivery_workforce.dart' as delivery;
import 'package:loyalty_levels/loyalty_levels.dart' as loyalty;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // SYSTEM CORE BOOTSTRAP (Normally in a ServiceLocator / Bootstrap file)
    // -------------------------------------------------------------------------

    // 1. Ports
    final supplyClock = supply.SystemClock();
    final appClock = AppClock();
    final eventBus = AppEventBus();

    // 2. Domains
    // Supply
    final inventory = supply.Inventory(id: 'main-inv', clock: supplyClock);
    // Seed some data for viewing (since we lack backend)
    try {
      inventory.addProduct(
        productId: supply.ProductId('MILK-1L'),
        initialQuantity: supply.Quantity(50),
        unit: supply.Unit.liters,
        reorderPoint: supply.Quantity(10),
        productType: supply.ProductType.consumable,
      );
    } catch (_) {} // Ignore if already exists (hot reload)

    final inventoryService = supply.InventoryManagementService(
      inventory: inventory,
      restockPolicy: const supply.RestockPolicy(),
      clock: supplyClock,
    );

    // 3. Orchestrators
    final supplyOrchestrator = SupplyFlowOrchestrator(
      inventoryService: inventoryService,
      clock: appClock,
      eventBus: eventBus,
    );

    // 3b. Order Orchestrator & UseCase Setup
    final orderService = ordering.OrderService(
      orderRepository: MainOrderRepo(),
      inventoryPort: MainInventoryPortAdapter(),
      pricingPort: MainPricingPortAdapter(),
      loyaltyPort: MainLoyaltyPortAdapter(),
    );

    final assignmentService = delivery.AssignmentManagementService(
      delivery.SystemClock(),
      delivery.AssignmentPolicy(),
    );
    final loyaltyService = loyalty.LoyaltyEvaluationService(
      clock: loyalty.SystemClock(),
    );

    final orderOrchestrator = OrderFlowOrchestrator(
      orderService: orderService,
      inventoryService: inventoryService,
      assignmentService: assignmentService,
      loyaltyService: loyaltyService,
      clock: appClock,
      eventBus: eventBus,
      domainEventBus: InMemoryDomainEventBus(),
    );

    final placeOrderUseCase = PlaceOrderFromAppUseCase(
      orderPlacementUseCase: OrderPlacementUseCase(
        orchestrator: orderOrchestrator,
        clock: appClock,
        eventBus: eventBus,
      ),
      clock: appClock,
      agentProvider: MainAgentProvider(),
      routeProvider: MainRouteProvider(),
      loyaltyAccountProvider: MainLoyaltyProvider(),
    );

    // 4. Infrastructure
    final realSystem = RealSystemOrchestrator(
      supplyOrchestrator: supplyOrchestrator,
      placeOrderUseCase: placeOrderUseCase,
    );

    // 5. Facade (Wraps a "Current Customer" - hardcoded for this demo)
    final currentUser = Customer(
      id: CustomerId('demo-user-1'),
      contactInfo: ContactInfo(phoneNumber: '9876543210'),
      status: CustomerStatus.active,
    );

    final customerFacade = CustomerAggregateFacade(
      customer: currentUser,
      orchestrator: realSystem,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
        // Provide Facade Globally
        RepositoryProvider<CustomerAggregateFacade>.value(
          value: customerFacade,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>()),
          ),
          // Provide ProductBloc Globally
          BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(
              customerFacade: context.read<CustomerAggregateFacade>(),
            ),
          ),
          BlocProvider<PlaceOrderBloc>(
            create: (context) => PlaceOrderBloc(
              customerFacade: context.read<CustomerAggregateFacade>(),
            ),
          ),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home:
              ProductListScreen(), // Switch simple login to product list for verification
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ADAPTERS (Local for now to satisfy DI)
// -----------------------------------------------------------------------------

class AppClock implements ClockPort {
  @override
  DateTime now() => DateTime.now();
}

class AppEventBus implements EventBusPort {
  @override
  void emit(event) {
    debugPrint('[EVENT BUS] $event');
  }
}

// -----------------------------------------------------------------------------
// MAIN ADAPTERS (For bootstrapping without backend)
// -----------------------------------------------------------------------------

class MainOrderRepo implements ordering.OrderRepository {
  @override
  ordering.Order findById(String id) => throw UnimplementedError();
  @override
  void save(ordering.Order order) {
    debugPrint('Order Saved: ${order.orderId}');
  }

  @override
  void update(ordering.Order order) {}
}

class MainInventoryPortAdapter implements ordering.InventoryPort {
  @override
  bool isAvailable({required String productId, required double quantity}) =>
      true; // Always say yes for demo
  @override
  void release({
    required String productId,
    required double quantity,
    required String orderId,
  }) {}
  @override
  void reserve({
    required String productId,
    required double quantity,
    required String orderId,
  }) {}
}

class MainPricingPortAdapter implements ordering.PricingPort {
  @override
  ordering.Money getPrice({
    required String productId,
    required DateTime at,
    ordering.Subscription? subscription,
  }) {
    return ordering.Money.inrRupees(100);
  }
}

class MainLoyaltyPortAdapter implements ordering.LoyaltyPort {
  @override
  void addPoints({
    required String customerId,
    required String orderId,
    required ordering.Money orderAmount,
  }) {}
  @override
  double applyDiscount({
    required String customerId,
    required double orderAmount,
  }) => 0;
  @override
  bool isEligible({required String customerId}) => true;
  @override
  void revertPoints({required String customerId, required String orderId}) {}
}

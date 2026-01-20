import 'package:delivery_workforce/delivery_workforce.dart' as delivery;
import 'package:loyalty_levels/loyalty_levels.dart' as loyalty;
import 'package:narayan_system_core/narayan_system_core.dart';

// Stub Implementations for DI in Main (similar to test Fakes but for "App Run")

class MainAgentProvider implements AgentProviderPort {
  @override
  List<delivery.DeliveryAgent> getAvailableAgents() {
    // Temporary in-memory agent seeding for demo/testing
    return [
      delivery.DeliveryAgent(
        id: delivery.DeliveryAgentId('agent-1'),
        role: delivery.AgentRole.delivery,
        status: delivery.AgentStatus.active,
      ),
    ];
  }
}

class MainRouteProvider implements RouteProviderPort {
  @override
  delivery.Route getRouteForCustomer(String customerId) {
    return delivery.Route(
      id: delivery.RouteId('route-1'),
      startLocation: const delivery.GeoArea('A'),
      endLocation: const delivery.GeoArea('B'),
      distanceKm: 1.0,
    );
  }
}

class MainLoyaltyProvider implements LoyaltyAccountProviderPort {
  @override
  loyalty.LoyaltyAccount getAccountForCustomer(String customerId) {
    return loyalty.LoyaltyAccount.create(
      accountId: customerId,
      createdAt: DateTime.now(),
    );
  }
}

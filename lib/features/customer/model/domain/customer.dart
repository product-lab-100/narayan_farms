import 'package:equatable/equatable.dart';

import 'contact_info.dart';
import 'customer_id.dart';
import 'customer_status.dart';

/// **Customer**
///
/// The Aggregate Root for the Customer domain.
///
/// **Responsibilities**:
/// - Maintains the integrity of the customer's identity and state.
/// - Exposes intent-based behavior for state transitions.
/// - Implements strict invariants.
///
/// **Invariants**:
/// - MUST have a valid [CustomerId].
/// - MUST have valid [ContactInfo].
/// - MUST have a status (defaults to active if not provided).
class Customer extends Equatable {
  final CustomerId id;
  final ContactInfo contactInfo;
  final CustomerStatus status;

  Customer({
    required this.id,
    required this.contactInfo,
    this.status = CustomerStatus.active,
  });

  /// **activate**
  ///
  /// Transitions the customer to the [CustomerStatus.active] state.
  /// Returns a new [Customer] instance with the updated status.
  Customer activate() {
    return _copyWith(status: CustomerStatus.active);
  }

  /// **deactivate**
  ///
  /// Transitions the customer to the [CustomerStatus.inactive] state.
  /// Returns a new [Customer] instance with the updated status.
  Customer deactivate() {
    return _copyWith(status: CustomerStatus.inactive);
  }

  /// **markAsBlocked**
  ///
  /// Transitions the customer to the [CustomerStatus.blocked] state.
  /// Returns a new [Customer] instance with the updated status.
  Customer markAsBlocked() {
    return _copyWith(status: CustomerStatus.blocked);
  }

  /// Internal copyWith for behavior implementation.
  /// Not exposed publicly to prevent arbitrary state mutation.
  Customer _copyWith({
    CustomerId? id,
    ContactInfo? contactInfo,
    CustomerStatus? status,
  }) {
    return Customer(
      id: id ?? this.id,
      contactInfo: contactInfo ?? this.contactInfo,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, contactInfo, status];

  @override
  String toString() =>
      'Customer(id: $id, status: $status, contact: $contactInfo)';
}

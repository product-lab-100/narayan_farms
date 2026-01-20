import 'package:equatable/equatable.dart';

/// **CustomerId**
///
/// A purely domain-centric unique identifier for a Customer.
///
/// **Responsibilities**:
/// - Encapsulates the concept of a unique customer ID.
/// - Enforces that an ID cannot be empty.
/// - Ensures value-based equality.
///
/// **Invariants**:
/// - Value must NOT be empty or null.
class CustomerId extends Equatable {
  final String value;

  CustomerId(this.value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('CustomerId cannot be empty');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'CustomerId($value)';
}

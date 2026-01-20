import 'package:equatable/equatable.dart';

/// **ContactInfo**
///
/// Represents the contact details of a customer.
///
/// **Responsibilities**:
/// - Encapsulates phone number and email.
/// - Enforces validation rules for phone numbers.
/// - Immutable value object.
///
/// **Invariants**:
/// - Phone number must NOT be empty.
/// - Phone number must contain 10-15 digits (basic validation).
class ContactInfo extends Equatable {
  final String phoneNumber;
  final String? email;

  ContactInfo({required this.phoneNumber, this.email}) {
    if (phoneNumber.trim().isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    // Basic regex: Allow optional + at start, then 10-15 digits.
    // Ignores spaces/dashes for validation check if we stripped them,
    // but here we enforce strict digit matching for simplicity or allow simple formatting.
    // Let's enforce a clean digit format of 10-15 length for domain purity.
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(phoneNumber)) {
      throw ArgumentError('Invalid phone number format: $phoneNumber');
    }
  }

  @override
  List<Object?> get props => [phoneNumber, email];

  @override
  String toString() => 'ContactInfo(phone: $phoneNumber, email: $email)';
}

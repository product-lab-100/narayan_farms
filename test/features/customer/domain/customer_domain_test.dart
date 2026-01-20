import 'package:flutter_test/flutter_test.dart';
import 'package:narayan_farms/features/customer/model/domain/contact_info.dart';
import 'package:narayan_farms/features/customer/model/domain/customer.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_id.dart';
import 'package:narayan_farms/features/customer/model/domain/customer_status.dart';

void main() {
  group('Customer Domain Entities', () {
    group('CustomerId', () {
      test('should create instance with valid value', () {
        var id = CustomerId('123');
        expect(id.value, '123');
      });

      test('should support value equality', () {
        var id1 = CustomerId('123');
        var id2 = CustomerId('123');
        var id3 = CustomerId('456');

        expect(id1, equals(id2));
        expect(id1, isNot(equals(id3)));
      });

      test('should throw ArgumentError when value is empty', () {
        expect(() => CustomerId(''), throwsArgumentError);
        expect(() => CustomerId('   '), throwsArgumentError);
      });
    });

    group('ContactInfo', () {
      test('should create instance with valid phone number', () {
        final contact = ContactInfo(phoneNumber: '1234567890');
        expect(contact.phoneNumber, '1234567890');
        expect(contact.email, isNull);
      });

      test('should create instance with valid phone number and email', () {
        final contact = ContactInfo(
          phoneNumber: '+1234567890',
          email: 'test@example.com',
        );
        expect(contact.phoneNumber, '+1234567890');
        expect(contact.email, 'test@example.com');
      });

      test('should throw ArgumentError when phone number is empty', () {
        expect(() => ContactInfo(phoneNumber: ''), throwsArgumentError);
      });

      test(
        'should throw ArgumentError when phone number format is invalid',
        () {
          expect(() => ContactInfo(phoneNumber: 'abc'), throwsArgumentError);
          expect(
            () => ContactInfo(phoneNumber: '123'),
            throwsArgumentError,
          ); // Too short
        },
      );

      test('should support value equality', () {
        final c1 = ContactInfo(phoneNumber: '1234567890');
        final c2 = ContactInfo(phoneNumber: '1234567890');
        expect(c1, equals(c2));
      });
    });

    group('Customer', () {
      final id = CustomerId('cust-1');
      final contact = ContactInfo(phoneNumber: '9876543210');

      test('should create active customer by default', () {
        final customer = Customer(id: id, contactInfo: contact);
        expect(customer.status, CustomerStatus.active);
      });

      test('should activate customer', () {
        var customer = Customer(
          id: id,
          contactInfo: contact,
          status: CustomerStatus.inactive,
        );

        customer = customer.activate();

        expect(customer.status, CustomerStatus.active);
      });

      test('should deactivate customer', () {
        var customer = Customer(id: id, contactInfo: contact);

        customer = customer.deactivate();

        expect(customer.status, CustomerStatus.inactive);
      });

      test('should block customer', () {
        var customer = Customer(id: id, contactInfo: contact);

        customer = customer.markAsBlocked();

        expect(customer.status, CustomerStatus.blocked);
      });

      test('should support equality', () {
        final c1 = Customer(id: id, contactInfo: contact);
        final c2 = Customer(id: id, contactInfo: contact);
        expect(c1, equals(c2));
      });
    });
  });
}

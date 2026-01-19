part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String name;

  const SendOtpEvent({required this.phoneNumber, required this.name});

  @override
  List<Object> get props => [phoneNumber, name];
}

class VerifyOtpEvent extends AuthEvent {
  final String verificationId;
  final String otp;
  final String name;
  final String phoneNumber;

  const VerifyOtpEvent(
      {required this.verificationId,
      required this.otp,
      required this.name,
      required this.phoneNumber});

  @override
  List<Object> get props => [verificationId, otp, name, phoneNumber];
}

class OnPhoneAuthErrorEvent extends AuthEvent {
  final String error;

  const OnPhoneAuthErrorEvent({required this.error});

  @override
  List<Object> get props => [error];
}

class OnPhoneAuthVerificationCompleteEvent extends AuthEvent {
  final PhoneAuthCredential credential;

  const OnPhoneAuthVerificationCompleteEvent({required this.credential});

  @override
  List<Object> get props => [credential];
}

class OnCodeSentEvent extends AuthEvent {
  final String verificationId;
  final int? token;

  const OnCodeSentEvent({required this.verificationId, required this.token});

  @override
  List<Object> get props => [verificationId];
}

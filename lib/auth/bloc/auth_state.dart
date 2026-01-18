part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthCodeSentState extends AuthState {
  final String verificationId;

  const AuthCodeSentState({required this.verificationId});

  @override
  List<Object> get props => [verificationId];
}

class AuthLoggedInState extends AuthState {
  final User user;

  const AuthLoggedInState({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthLoggedOutState extends AuthState {}

class AuthErrorState extends AuthState {
  final String error;

  const AuthErrorState({required this.error});

  @override
  List<Object> get props => [error];
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:narayan_farms/features/auth/model/repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  String _name = '';
  String _phoneNumber = '';

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<OnPhoneAuthErrorEvent>(_onPhoneAuthError);
    on<OnPhoneAuthVerificationCompleteEvent>(_onPhoneAuthVerificationComplete);
    on<OnCodeSentEvent>(_onCodeSent);
  }

  void _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    _name = event.name;
    _phoneNumber = event.phoneNumber;
    try {
      await authRepository.signInWithPhone(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          add(OnPhoneAuthVerificationCompleteEvent(credential: credential));
        },
        verificationFailed: (FirebaseAuthException e) {
          add(OnPhoneAuthErrorEvent(error: e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          add(
            OnCodeSentEvent(verificationId: verificationId, token: resendToken),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      emit(AuthErrorState(error: e.toString()));
    }
  }

  void _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      await authRepository.verifyOTP(
        verificationId: event.verificationId,
        userOTP: event.otp,
      );
      await authRepository.storeUserData(event.name, event.phoneNumber);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(AuthLoggedInState(user: user));
      } else {
        emit(const AuthErrorState(error: 'User not found'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthErrorState(error: e.code));
    } catch (e) {
      emit(AuthErrorState(error: e.toString()));
    }
  }

  void _onPhoneAuthError(OnPhoneAuthErrorEvent event, Emitter<AuthState> emit) {
    emit(AuthErrorState(error: event.error));
  }

  void _onPhoneAuthVerificationComplete(
    OnPhoneAuthVerificationCompleteEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        event.credential,
      );
      final user = userCredential.user;
      if (user != null) {
        await authRepository.storeUserData(_name, _phoneNumber);
        emit(AuthLoggedInState(user: user));
      } else {
        emit(const AuthErrorState(error: 'User not found'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthErrorState(error: e.code));
    } catch (e) {
      emit(AuthErrorState(error: e.toString()));
    }
  }

  void _onCodeSent(OnCodeSentEvent event, Emitter<AuthState> emit) {
    emit(AuthCodeSentState(verificationId: event.verificationId));
  }
}

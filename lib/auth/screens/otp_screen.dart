import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms/auth/bloc/auth_bloc.dart';
import 'package:narayan_farms/auth/screens/success_screen.dart';

class OtpScreen extends StatelessWidget {
  final String verificationId;
  final String name;
  final String phoneNumber;
  const OtpScreen(
      {super.key,
      required this.verificationId,
      required this.name,
      required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedInState) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SuccessScreen(),
              ),
              (route) => false,
            );
          }
          if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Verification Code',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('We have sent the verification code to your phone no.'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoadingState) {
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          context.read<AuthBloc>().add(
                                VerifyOtpEvent(
                                  verificationId: verificationId,
                                  otp: otpController.text,
                                  name: name,
                                  phoneNumber: phoneNumber,
                                ),
                              );
                        }
                      },
                      child: const Text('Confirm'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

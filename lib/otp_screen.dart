import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String verificationId = '';
  bool otpSent = false;
  bool isLoading = false;

  void sendOTP() async {
    String phone = phoneController.text.trim();

    if (!phone.startsWith('+')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please include country code, e.g. +92XXXXXXXXXX')),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        navigateToHome();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
        setState(() => isLoading = false);
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {},
    );
  }

  void verifyOTP() async {
    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP! Please try again.')),
      );
      setState(() => isLoading = false);
    }
  }

  void navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Card(
            elevation: 8,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 60, color: Colors.green.shade700),
                  const SizedBox(height: 16),
                  Text(
                    otpSent ? "Verify OTP" : "Login with Number",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 24),
                  if (!otpSent) ...[
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+923000000000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                        const Icon(Icons.phone, color: Colors.green),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ] else ...[
                    TextField(
                      controller: otpController,
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        hintText: '6-digit code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                        const Icon(Icons.verified, color: Colors.green),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading ? null : sendOTP,
                      child: const Text("Resend OTP"),
                    ),
                  ],
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: otpSent ? verifyOTP : sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        otpSent ? 'Verify OTP' : 'Send OTP',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart';
import 'home_screen.dart';
import 'firebase_options.dart'; // will be auto-generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OTP Login Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: FirebaseAuth.instance.currentUser == null
          ? const OTPScreen()
          : const HomeScreen(),
    );
  }
}

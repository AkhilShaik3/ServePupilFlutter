import 'dart:async';
import 'package:flutter/material.dart';
import 'SignUpPage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignUpPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/servepupil_logo.jpg', // Make sure to add your image in pubspec.yaml
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'ServePupil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }
}

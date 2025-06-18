import 'package:flutter/material.dart';
import 'package:servepupil/LoginPage.dart';
import 'package:servepupil/UserListView.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Row with Back Arrow and Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/servepupil_logo.jpg',
                    height: 40,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Title
            const Text(
              'Admin Home Page',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _buildButton(context, 'View Users', Colors.teal, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserListPage()),
                    );
                  }),
                  const SizedBox(height: 15),
                  _buildButton(context, 'View Reports', Colors.teal, () {

                  }),
                  const SizedBox(height: 15),
                  _buildButton(context, 'View Requests', Colors.teal, () {

                  }),
                  const SizedBox(height: 15),
                  _buildButton(context, 'Logout', Colors.red, () {
                    // Navigate to login and clear all previous routes
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

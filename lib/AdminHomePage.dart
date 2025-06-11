import 'package:flutter/material.dart';

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
                  _buildButton(context, 'Profile', Colors.teal, () {
                    // Navigate to Profile Page
                  }),
                  const SizedBox(height: 15),
                  _buildButton(context, 'Create Request', Colors.teal, () {
                    // Navigate to Create Request Page
                  }),
                  const SizedBox(height: 15),
                  _buildButton(context, 'View Others Requests', Colors.teal, () {
                    // Navigate to View Others' Requests Page
                  }),
                  const SizedBox(height: 15),
                  _buildButton(context, 'View My Requests', Colors.teal, () {
                    // Navigate to My Requests Page
                  }),
                  const SizedBox(height: 15),
                  _buildButton(context, 'Logout', Colors.red, () {
                    // Handle logout logic
                    Navigator.pop(context);
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

import 'package:flutter/material.dart';
import 'package:servepupil/ReportedCommentsPage.dart';
import 'package:servepupil/ReportedUsersPage.dart';
import 'ReportedRequestsView.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReportButton(context, "Reported Requests", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportedRequestsView()),
              );
            }),
            const SizedBox(height: 20),
            _buildReportButton(context, "Reported Users", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportedUsersPage()),
              );
            }),
            const SizedBox(height: 20),
            _buildReportButton(context, "Reported Comments", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportedCommentsPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, String title, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

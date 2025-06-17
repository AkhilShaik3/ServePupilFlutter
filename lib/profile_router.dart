import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../CreateProfilePage.dart';
import '../ProfileViewPage.dart';

class ProfileRouter extends StatelessWidget {
  const ProfileRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseDatabase.instance.ref().child('users/$uid');

    return FutureBuilder(
      future: userRef.once(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final exists = snapshot.data?.snapshot.exists ?? false;
        if (exists) {
          return ProfileViewPage();
        } else {
          return CreateProfilePage();
        }
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../user_profile.dart';

class ProfileViewPage extends StatelessWidget {
  const ProfileViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseDatabase.instance.ref().child('users/$uid');

    return FutureBuilder(
      future: userRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.value == null) {
          return const Center(child: Text("Profile not found"));
        }

        final userProfile = UserProfile.fromJson(
          Map<String, dynamic>.from(snapshot.data!.value as Map),
        );

        return Scaffold(
          appBar: AppBar(title: const Text("Profile")),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(userProfile.imageUrl),
                  radius: 50,
                ),
                const SizedBox(height: 20),
                Text(userProfile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Phone: ${userProfile.phone}"),
                Text("Bio: ${userProfile.bio}"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(children: [Text("${userProfile.followers}"), const Text("Followers")]),
                    const SizedBox(width: 40),
                    Column(children: [Text("${userProfile.following}"), const Text("Following")]),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Edit Profile"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:servepupil/EditProfilePage.dart';
import '../user_profile.dart';
import 'ChangePasswordPage.dart';

class ProfileViewPage extends StatelessWidget {
  const ProfileViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseDatabase.instance.ref().child('users/$uid');

    return FutureBuilder<DataSnapshot>(
      future: userRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data?.value == null) {
          return const Scaffold(body: Center(child: Text("Profile not found")));
        }

        final rawData = Map<String, dynamic>.from(snapshot.data!.value as Map);

        final userProfile = UserProfile.fromJson(rawData);

        final followers = rawData['followers'];
        final following = rawData['following'];

        final int followersCount =
        followers is Map ? followers.length : (followers is int ? followers : 0);
        final int followingCount =
        following is Map ? following.length : (following is int ? following : 0);

        return Scaffold(
          appBar: AppBar(title: const Text("Profile")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: userProfile.imageUrl.isNotEmpty
                      ? Image.network(
                    userProfile.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 80, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  userProfile.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(userProfile.phone),
                const SizedBox(height: 4),
                Text(userProfile.bio),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text("$followersCount", style: const TextStyle(fontSize: 16)),
                        const Text("Followers"),
                      ],
                    ),
                    const SizedBox(width: 40),
                    Column(
                      children: [
                        Text("$followingCount", style: const TextStyle(fontSize: 16)),
                        const Text("Following"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfilePage()),
                    );
                  },
                  child: const Text("Edit Profile"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                    );
                  },
                  child: const Text(
                    "Change Password",
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

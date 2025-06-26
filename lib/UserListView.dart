import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:servepupil/AdminEditProfilePage.dart';
import 'user_profile.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');

  void toggleBlock(String uid, bool currentStatus) {
    final newStatus = !currentStatus;
    usersRef.child(uid).child("isBlocked").set(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users List")),
      body: StreamBuilder(
        stream: usersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No users found"));
          }

          final data = snapshot.data!.snapshot.value as Map;
          final List<Map<String, dynamic>> usersWithStatus = [];

          data.forEach((key, value) {
            final userMap = value as Map;
            final profile = UserProfile.fromJson(Map<String, dynamic>.from(userMap));
            final isBlocked = userMap['isBlocked'] ?? false;

            usersWithStatus.add({
              'uid': key,
              'profile': profile,
              'isBlocked': isBlocked,
            });
          });

          return ListView.builder(
            itemCount: usersWithStatus.length,
            itemBuilder: (context, index) {
              final user = usersWithStatus[index];
              final uid = user['uid'];
              final profile = user['profile'] as UserProfile;
              final isBlocked = user['isBlocked'] as bool;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profile.imageUrl.isNotEmpty
                      ? NetworkImage(profile.imageUrl)
                      : const AssetImage('assets/images/default_user.png') as ImageProvider,
                  radius: 25,
                ),
                title: Text(profile.name),
                subtitle: Text(profile.phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminEditProfilePage(
                              uid: uid,
                              name: profile.name,
                              phone: profile.phone,
                              address: profile.bio,
                            ),
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => toggleBlock(uid, isBlocked),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? Colors.teal : Colors.red,
                      ),
                      child: Text(isBlocked ? "UnBlock" : "Block"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

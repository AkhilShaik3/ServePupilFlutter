import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'user_profile.dart';
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');
  List<Map<String, dynamic>> usersWithStatus = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    final event = await usersRef.once();
    final data = event.snapshot.value as Map?;

    if (data != null) {
      final List<Map<String, dynamic>> loadedUsers = [];

      data.forEach((key, value) {
        final userMap = value as Map;
        final profile = UserProfile.fromJson(Map<String, dynamic>.from(userMap));

        final isBlocked = userMap['isBlocked'] ?? false;

        loadedUsers.add({
          'uid': key,
          'profile': profile,
          'isBlocked': isBlocked,
        });
      });

      setState(() {
        usersWithStatus = loadedUsers;
      });
    }
  }

  void toggleBlock(String uid, bool currentStatus) {
    final newStatus = !currentStatus;
    usersRef.child(uid).child("isBlocked").set(newStatus);
    setState(() {
      final index = usersWithStatus.indexWhere((user) => user['uid'] == uid);
      if (index != -1) {
        usersWithStatus[index]['isBlocked'] = newStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users List")),
      body: ListView.builder(
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
                    // Navigate to edit profile
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
      ),
    );
  }
}

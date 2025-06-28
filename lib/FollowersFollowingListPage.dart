import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FollowersFollowingListPage extends StatefulWidget {
  final String uid;
  final String title; // "Followers" or "Following"
  final String listType; // "followers" or "following"

  const FollowersFollowingListPage({
    super.key,
    required this.uid,
    required this.title,
    required this.listType,
  });

  @override
  State<FollowersFollowingListPage> createState() => _FollowersFollowingListPageState();
}

class _FollowersFollowingListPageState extends State<FollowersFollowingListPage> {
  final dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, String>> usersList = [];

  @override
  void initState() {
    super.initState();
    _listenToList();
  }

  void _listenToList() {
    dbRef.child('users/${widget.uid}/${widget.listType}').onValue.listen((event) async {
      if (!mounted) return;

      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> map = event.snapshot.value as Map;
        final List<Map<String, String>> tempList = [];

        for (final key in map.keys) {
          final userSnapshot = await dbRef.child('users/$key').get();
          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            tempList.add({
              'uid': key,
              'name': userData['name'] ?? '',
              'imageUrl': userData['imageUrl'] ?? '',
            });
          }
        }

        if (mounted) {
          setState(() {
            usersList = tempList;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            usersList = [];
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: usersList.isEmpty
          ? Center(
        child: Text(
          widget.listType == "followers"
              ? "No followers yet"
              : "No following yet",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: usersList.length,
        itemBuilder: (context, index) {
          final user = usersList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user['imageUrl']!.isNotEmpty
                  ? NetworkImage(user['imageUrl']!)
                  : const AssetImage('assets/images/default_user.png') as ImageProvider,
            ),
            title: Text(user['name']!),
          );
        },
      ),
    );
  }
}

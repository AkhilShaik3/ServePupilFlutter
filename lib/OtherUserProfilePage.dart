import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String uid;

  const OtherUserProfilePage({required this.uid});

  @override
  _OtherUserProfilePageState createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final dbRef = FirebaseDatabase.instance.ref();

  String userName = "";
  String phone = "";
  String address = "";
  String imageUrl = "";
  int followersCount = 0;
  int followingCount = 0;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    listenToFollowingStatus();
  }

  void fetchUserDetails() {
    final ref = dbRef.child('users/${widget.uid}');
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final userData = Map<String, dynamic>.from(data);
        setState(() {
          userName = userData['name'] ?? '';
          phone = userData['phone'] ?? '';
          address = userData['address'] ?? '';
          imageUrl = userData['imageUrl'] ?? '';
          followersCount = userData['followers'] is Map ? (userData['followers'] as Map).length : 0;
          followingCount = userData['following'] is Map ? (userData['following'] as Map).length : 0;
        });
      }
    });
  }

  void listenToFollowingStatus() {
    final followingRef = dbRef.child('users/${user!.uid}/following/${widget.uid}');
    followingRef.onValue.listen((event) {
      setState(() {
        isFollowing = event.snapshot.exists;
      });
    });
  }

  void toggleFollow() async {
    final myUid = user!.uid;
    final otherUid = widget.uid;

    final myFollowingRef = dbRef.child('users/$myUid/following/$otherUid');
    final otherFollowersRef = dbRef.child('users/$otherUid/followers/$myUid');

    if (isFollowing) {
      await myFollowingRef.remove();
      await otherFollowersRef.remove();
    } else {
      await myFollowingRef.set(true);
      await otherFollowersRef.set(true);
    }
  }

  void reportUser() async {
    final reportRef = dbRef.child('reported_content/users/${widget.uid}');
    final snapshot = await reportRef.get();

    if (snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("This user has already been reported")),
      );
    } else {
      await reportRef.set(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User reported successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        leading: BackButton(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            // Profile Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
                  : Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 80, color: Colors.grey),
              ),
            ),
            SizedBox(height: 16),

            // Name, phone, address
            Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(phone, style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text(address, style: TextStyle(fontSize: 16, color: Colors.grey[700])),

            SizedBox(height: 20),

            // Followers and Following + Follow button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('$followersCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Followers'),
                  ],
                ),
                Column(
                  children: [
                    Text('$followingCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Following'),
                  ],
                ),
                ElevatedButton(
                  onPressed: toggleFollow,
                  child: Text(isFollowing ? "Unfollow" : "Follow"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                )
              ],
            ),

            SizedBox(height: 30),

            // Report button
            ElevatedButton(
              onPressed: reportUser,
              child: Text("Report User"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 150, vertical: 14),
              ),
            )
          ],
        ),
      ),
    );
  }
}

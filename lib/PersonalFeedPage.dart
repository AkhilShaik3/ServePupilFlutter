import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'CommentsPage.dart';
import 'OtherUserProfilePage.dart';
import 'ProfileViewPage.dart';

class PersonalFeedPage extends StatefulWidget {
  @override
  _PersonalFeedPageState createState() => _PersonalFeedPageState();
}

class _PersonalFeedPageState extends State<PersonalFeedPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  Map<String, String> userNamesCache = {};

  Future<String> fetchUserName(String uid) async {
    if (userNamesCache.containsKey(uid)) return userNamesCache[uid]!;

    final snapshot = await FirebaseDatabase.instance.ref('users/$uid/name').get();
    final name = snapshot.value?.toString() ?? "User";
    userNamesCache[uid] = name;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final followingRef = FirebaseDatabase.instance.ref('users/${currentUser!.uid}/following');

    return Scaffold(
      appBar: AppBar(title: Text("Personal Feed")),
      body: StreamBuilder(
        stream: followingRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> followSnap) {
          if (!followSnap.hasData || followSnap.data!.snapshot.value == null) {
            return Center(child: Text("You're not following anyone"));
          }

          final followMap = Map<String, dynamic>.from(followSnap.data!.snapshot.value as Map);
          final followingUids = followMap.keys.toSet();

          return StreamBuilder(
            stream: FirebaseDatabase.instance.ref('requests').onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> requestSnap) {
              if (!requestSnap.hasData || requestSnap.data!.snapshot.value == null) {
                return Center(child: Text("No requests found"));
              }

              final allRequests = Map<String, dynamic>.from(requestSnap.data!.snapshot.value as Map);
              List<Widget> requestCards = [];

              allRequests.forEach((uid, userRequests) {
                if (!followingUids.contains(uid)) return;

                final requestMap = Map<String, dynamic>.from(userRequests);
                requestMap.forEach((reqId, data) {
                  final request = Map<String, dynamic>.from(data);
                  final imageUrl = request['imageUrl'] ?? '';
                  final description = request['description'] ?? '';
                  final requestType = request['requestType'] ?? '';
                  final place = request['place'] ?? '';
                  final comments = Map<String, dynamic>.from(request['comments'] ?? {});
                  final likedBy = Map<String, dynamic>.from(request['likedBy'] ?? {});
                  final commentCount = comments.length;
                  final likeCount = likedBy.length;
                  final isLikedByMe = likedBy.containsKey(currentUser!.uid);

                  requestCards.add(
                    FutureBuilder<String>(
                      future: fetchUserName(uid),
                      builder: (context, nameSnap) {
                        final userName = nameSnap.data ?? 'User';

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                                          : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image, size: 40, color: Colors.grey[700]),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(description,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(requestType, style: TextStyle(fontSize: 14)),
                                          Text(place, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            final ref = FirebaseDatabase.instance
                                                .ref('requests/$uid/$reqId/likedBy/${currentUser!.uid}');
                                            if (isLikedByMe) {
                                              ref.remove();
                                            } else {
                                              ref.set(true);
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                                color: isLikedByMe ? Colors.red : Colors.grey,
                                                size: 20,
                                              ),
                                              SizedBox(width: 4),
                                              Text('$likeCount'),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CommentsPage(
                                                  requestOwnerUid: uid,
                                                  requestId: reqId,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.chat_bubble_outline, size: 20),
                                              SizedBox(width: 4),
                                              Text('$commentCount'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    if (uid == currentUser!.uid) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileViewPage()));
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => OtherUserProfilePage(uid: uid)),
                                      );
                                    }
                                  },
                                  child: Center(
                                    child: Text(
                                      userName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    final reportRef =
                                    FirebaseDatabase.instance.ref('reported_content/requests/$reqId');
                                    final snapshot = await reportRef.get();

                                    if (snapshot.exists) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('This request has already been reported')),
                                      );
                                    } else {
                                      await reportRef.set(true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Request reported successfully')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Center(
                                    child: Text("Report Post", style: TextStyle(color: Colors.white)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                });
              });

              return ListView(children: requestCards);
            },
          );
        },
      ),
    );
  }
}

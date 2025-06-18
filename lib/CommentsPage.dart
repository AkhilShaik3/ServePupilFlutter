import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CommentsPage extends StatefulWidget {
  final String requestOwnerUid;
  final String requestId;

  CommentsPage({required this.requestOwnerUid, required this.requestId});

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final commentController = TextEditingController();
  final dbRef = FirebaseDatabase.instance.ref();
  final currentUser = FirebaseAuth.instance.currentUser;

  Map<String, String> userNameCache = {}; // cache usernames

  Future<String> getUserName(String uid) async {
    if (userNameCache.containsKey(uid)) {
      return userNameCache[uid]!;
    }

    final snapshot = await dbRef.child('users').child(uid).child('name').once();
    final name = snapshot.snapshot.value?.toString() ?? "Unknown";
    userNameCache[uid] = name;
    return name;
  }

  void postComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final commentRef = dbRef
        .child('requests')
        .child(widget.requestOwnerUid)
        .child(widget.requestId)
        .child('comments')
        .push();

    await commentRef.set({
      'uid': currentUser!.uid,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsRef = dbRef
        .child('requests')
        .child(widget.requestOwnerUid)
        .child(widget.requestId)
        .child('comments');

    return Scaffold(
      appBar: AppBar(title: Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: commentsRef.orderByChild('timestamp').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(child: Text("No comments yet"));
                }

                final commentsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final entries = commentsMap.entries.toList()
                  ..sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final commentData = Map<String, dynamic>.from(entries[index].value);
                    final uid = commentData['uid'] ?? '';
                    final text = commentData['text'] ?? '';
                    final timestamp = commentData['timestamp'] ?? 0;

                    return FutureBuilder<String>(
                      future: getUserName(uid),
                      builder: (context, snapshot) {
                        final name = snapshot.data ?? "Loading...";
                        return ListTile(
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(text),
                          trailing: Text(
                            DateTime.fromMillisecondsSinceEpoch(timestamp)
                                .toLocal()
                                .toString()
                                .split('.')[0],
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: postComment,
                  child: Text("Post"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

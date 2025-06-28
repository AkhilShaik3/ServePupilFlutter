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

  Map<String, String> userNameCache = {};
  String? currentUserEmail;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    getCurrentUserInfo();
  }

  Future<void> getCurrentUserInfo() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      final snapshot = await dbRef.child('users/$uid/email').get();
      currentUserEmail = snapshot.value?.toString() ?? '';
      isAdmin = currentUserEmail == 'admin@gmail.com'; // adjust your admin email
      setState(() {});
    }
  }

  Future<String> getUserName(String uid) async {
    if (userNameCache.containsKey(uid)) return userNameCache[uid]!;

    final snapshot = await dbRef.child('users/$uid/name').get();
    final name = snapshot.value?.toString() ?? "Unknown";
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

  void deleteComment(String commentId) async {
    await dbRef
        .child('requests/${widget.requestOwnerUid}/${widget.requestId}/comments/$commentId')
        .remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comment deleted')),
    );
  }

  void reportComment(String commentId) async {
    final ref = dbRef.child('reported_content/comments/$commentId');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This comment has already been reported')),
      );
    } else {
      await ref.set(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment reported successfully')),
      );
    }
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

                final commentsMap =
                Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final entries = commentsMap.entries.toList()
                  ..sort((a, b) =>
                      (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final commentId = entries[index].key;
                    final commentData = Map<String, dynamic>.from(entries[index].value);
                    final uid = commentData['uid'] ?? '';
                    final text = commentData['text'] ?? '';
                    final timestamp = commentData['timestamp'] ?? 0;

                    return FutureBuilder<String>(
                      future: getUserName(uid),
                      builder: (context, snapshot) {
                        final name = snapshot.data ?? "Loading...";
                        final isMyComment = uid == currentUser?.uid;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text(text),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateTime.fromMillisecondsSinceEpoch(timestamp)
                                        .toLocal()
                                        .toString()
                                        .split('.')[0],
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  if (!isMyComment)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(0, 30),
                                      ),
                                      child: Text(isAdmin ? "Delete" : "Report"),
                                      onPressed: () {
                                        if (isAdmin) {
                                          deleteComment(commentId);
                                        } else {
                                          reportComment(commentId);
                                        }
                                      },
                                    ),
                                ],
                              ),
                              Divider(height: 16),
                            ],
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

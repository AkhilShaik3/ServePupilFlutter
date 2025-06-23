import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RequestCommentsPage extends StatefulWidget {
  final String ownerUid;
  final String requestId;

  const RequestCommentsPage({required this.ownerUid, required this.requestId});

  @override
  _RequestCommentsPageState createState() => _RequestCommentsPageState();
}

class _RequestCommentsPageState extends State<RequestCommentsPage> {
  final dbRef = FirebaseDatabase.instance.ref();
  Map<String, String> userNameCache = {};

  Future<String> fetchUserName(String uid) async {
    if (userNameCache.containsKey(uid)) return userNameCache[uid]!;

    final snap = await dbRef.child('users/$uid/name').get();
    final name = snap.value?.toString() ?? 'User';
    userNameCache[uid] = name;
    return name;
  }

  Future<void> deleteComment(String commentId) async {
    await dbRef
        .child('requests/${widget.ownerUid}/${widget.requestId}/comments/$commentId')
        .remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comment deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Comments")),
      body: StreamBuilder(
        stream: dbRef
            .child('requests/${widget.ownerUid}/${widget.requestId}/comments')
            .onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("No comments for this request"));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final commentsList = data.entries.map((entry) {
            final value = Map<String, dynamic>.from(entry.value);
            value['commentId'] = entry.key;
            return value;
          }).toList();

          return ListView.builder(
            itemCount: commentsList.length,
            itemBuilder: (context, index) {
              final comment = commentsList[index];
              final uid = comment['uid'];
              final text = comment['text'] ?? '';
              final timestamp = comment['timestamp'] ?? 0;
              final commentId = comment['commentId'];

              return FutureBuilder<String>(
                future: fetchUserName(uid),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'User';

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
                            TextButton(
                              onPressed: () => deleteComment(commentId),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: Text("Delete"),
                            ),
                          ],
                        ),
                        Divider(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

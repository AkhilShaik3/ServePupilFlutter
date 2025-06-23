import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportedCommentsPage extends StatefulWidget {
  @override
  _ReportedCommentsPageState createState() => _ReportedCommentsPageState();
}

class _ReportedCommentsPageState extends State<ReportedCommentsPage> {
  final dbRef = FirebaseDatabase.instance.ref();
  Map<String, String> userNameCache = {};

  Future<String> fetchUserName(String uid) async {
    if (userNameCache.containsKey(uid)) return userNameCache[uid]!;

    final snapshot = await dbRef.child('users/$uid/name').get();
    final name = snapshot.value?.toString() ?? 'User';
    userNameCache[uid] = name;
    return name;
  }

  Future<List<Map<String, dynamic>>> fetchReportedComments(
      Map<String, dynamic> reportedMap) async {
    final allRequestsSnap = await dbRef.child('requests').get();
    List<Map<String, dynamic>> tempList = [];

    if (allRequestsSnap.exists) {
      final allRequests = Map<String, dynamic>.from(allRequestsSnap.value as Map);

      for (String commentId in reportedMap.keys) {
        for (String userId in allRequests.keys) {
          final userRequests = Map<String, dynamic>.from(allRequests[userId]);

          for (String reqId in userRequests.keys) {
            final commentsNode = Map<String, dynamic>.from(
                userRequests[reqId]['comments'] ?? {});

            if (commentsNode.containsKey(commentId)) {
              final comment = Map<String, dynamic>.from(commentsNode[commentId]);
              comment['uid'] = comment['uid'];
              comment['commentId'] = commentId;
              comment['requestOwnerUid'] = userId;
              comment['requestId'] = reqId;
              tempList.add(comment);
              break;
            }
          }
        }
      }
    }

    return tempList;
  }

  Future<void> deleteComment(String ownerUid, String requestId, String commentId) async {
    await dbRef.child('requests/$ownerUid/$requestId/comments/$commentId').remove();
    await dbRef.child('reported_content/comments/$commentId').remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comment deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reported Comments")),
      body: StreamBuilder(
        stream: dbRef.child('reported_content/comments').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("No reported comments"));
          }

          final reportedMap =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchReportedComments(reportedMap),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final reportedComments = snapshot.data!;
              if (reportedComments.isEmpty) {
                return Center(child: Text("No reported comments"));
              }

              return ListView.builder(
                itemCount: reportedComments.length,
                itemBuilder: (context, index) {
                  final comment = reportedComments[index];
                  final uid = comment['uid'];
                  final commentId = comment['commentId'];
                  final requestOwnerUid = comment['requestOwnerUid'];
                  final requestId = comment['requestId'];
                  final text = comment['text'] ?? '';
                  final timestamp = comment['timestamp'] ?? 0;

                  return FutureBuilder<String>(
                    future: fetchUserName(uid),
                    builder: (context, snap) {
                      final name = snap.data ?? "User";

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
                                  onPressed: () {
                                    deleteComment(requestOwnerUid, requestId, commentId);
                                  },
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
          );
        },
      ),
    );
  }
}
